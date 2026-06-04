import base64
import io
import os
import uuid
from datetime import datetime
from functools import wraps

import mysql.connector
import numpy as np
import tensorflow as tf
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from PIL import Image
from tensorflow.keras.applications.efficientnet import preprocess_input


# --- CREATION DE L'APPLICATION ---

app = Flask(__name__)
CORS(app)


# --- CONFIGURATION SIMPLE ---

MODEL_PATH = "models/best_model_b3_20260512_002223.keras"
IMG_SIZE = (300, 300)
UPLOAD_DIR = "uploads/scans"

DB_HOST = "localhost"
DB_USER = "root"
DB_PASSWORD = ""
DB_NAME = "waste_db"
API_KEY = os.environ.get("ECOTRI_API_KEY", "ecotri-demo-key")

CLASSES = ["biological", "metal", "paper", "plastic"]

CATEGORIES = {
    "biological": {
        "conseil": "Compostable - bac vert",
        "couleur": "vert",
        "bac": "bac vert",
    },
    "metal": {
        "conseil": "Recyclable - bac jaune",
        "couleur": "jaune",
        "bac": "bac jaune",
    },
    "paper": {
        "conseil": "Recyclable - bac bleu",
        "couleur": "bleu",
        "bac": "bac bleu",
    },
    "plastic": {
        "conseil": "Recyclable - bac jaune",
        "couleur": "jaune",
        "bac": "bac jaune",
    },
}

os.makedirs(UPLOAD_DIR, exist_ok=True)


def require_api_key(route):
    """Protege une route avec la cle envoyee dans le header X-API-Key."""
    @wraps(route)
    def wrapper(*args, **kwargs):
        received_key = request.headers.get("X-API-Key")

        if received_key != API_KEY:
            return jsonify({"error": "Cle API manquante ou invalide"}), 401

        return route(*args, **kwargs)

    return wrapper


# --- CHARGEMENT DU MODELE ---

try:
    model = tf.keras.models.load_model(MODEL_PATH)
    print("Modele charge :", MODEL_PATH)
except Exception as e:
    print("Erreur chargement modele :", e)
    model = None


# --- FONCTIONS BASE DE DONNEES ---

def get_db():
    """Ouvre une connexion MySQL."""
    try:
        db = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
        )
        return db
    except mysql.connector.Error as e:
        print("Erreur MySQL :", e)
        return None


def init_categories():
    """Ajoute les categories dans MySQL si elles n'existent pas encore."""
    db = get_db()
    if db is None:
        print("Impossible de se connecter a MySQL")
        return

    cur = db.cursor()

    for name, details in CATEGORIES.items():
        cur.execute(
            """
            INSERT INTO categories (nom, conseil, couleur, bac)
            VALUES (%s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                conseil = VALUES(conseil),
                couleur = VALUES(couleur),
                bac = VALUES(bac)
            """,
            (name, details["conseil"], details["couleur"], details["bac"]),
        )

    db.commit()
    cur.close()
    db.close()
    print("Categories initialisees")


def get_category_id(class_name, cur):
    """Retourne l'id MySQL d'une categorie."""
    cur.execute("SELECT id FROM categories WHERE nom = %s", (class_name,))
    row = cur.fetchone()

    if row is None:
        raise ValueError("Categorie inconnue : " + class_name)

    return row[0]


# --- FONCTIONS IMAGE ---

def read_image_from_request(data):
    """Transforme l'image base64 recue en image PIL."""
    if data is None or "image" not in data:
        raise ValueError("Image manquante")

    image_base64 = data["image"]
    if not isinstance(image_base64, str) or image_base64 == "":
        raise ValueError("Image invalide")

    if image_base64.startswith("data:image"):
        image_base64 = image_base64.split(",", 1)[1]

    try:
        image_bytes = base64.b64decode(image_base64)
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as e:
        raise ValueError("Image invalide") from e

    return image


def save_image(image):
    """Sauvegarde l'image scannee et retourne son chemin."""
    filename = "scan_" + datetime.now().strftime("%Y%m%d_%H%M%S") + "_" + uuid.uuid4().hex[:8] + ".jpg"
    path = os.path.join(UPLOAD_DIR, filename)

    image.save(path, format="JPEG", quality=90)

    return path.replace("\\", "/")


def make_image_url(image_path):
    """Construit l'URL complete de l'image."""
    if not image_path:
        return None

    return request.host_url.rstrip("/") + "/" + image_path


# --- ROUTES API ---

@app.route("/", methods=["GET"])
def index():
    return jsonify({
        "app": "EcoTri AI API",
        "version": "1.0",
        "endpoints": [
            "GET /health",
            "GET /historique",
            "GET /stats",
            "POST /predict",
            "DELETE /delete/<id>",
        ],
    })


@app.route("/health", methods=["GET"])
def health():
    db = get_db()
    database_status = "connected" if db else "disconnected"

    if db:
        db.close()

    return jsonify({
        "status": "ok",
        "model_loaded": model is not None,
        "model": MODEL_PATH,
        "database": database_status,
        "classes": CLASSES,
    })


@app.route("/uploads/scans/<path:filename>", methods=["GET"])
def uploaded_scan(filename):
    return send_from_directory(UPLOAD_DIR, filename)


@app.route("/predict", methods=["POST"])
@require_api_key
def predict():
    if model is None:
        return jsonify({"error": "Modele non charge"}), 500

    try:
        data = request.get_json()
        image = read_image_from_request(data)

        image_path = save_image(image)

        resized_image = image.resize(IMG_SIZE)
        image_array = np.array(resized_image)
        image_array = np.expand_dims(image_array, axis=0)
        image_array = preprocess_input(image_array.astype(np.float32))

        predictions = model.predict(image_array, verbose=0)[0]
        best_index = int(np.argmax(predictions))

        class_name = CLASSES[best_index]
        confidence = float(predictions[best_index] * 100)

        db = get_db()
        if db:
            cur = db.cursor()

            category_id = get_category_id(class_name, cur)
            cur.execute(
                """
                INSERT INTO classifications (categorie_id, confiance, date_scan, image_path)
                VALUES (%s, %s, %s, %s)
                """,
                (category_id, confidence, datetime.now(), image_path),
            )

            db.commit()
            cur.close()
            db.close()

        all_probabilities = {}
        for i in range(len(CLASSES)):
            all_probabilities[CLASSES[i]] = round(float(predictions[i]) * 100, 2)

        return jsonify({
            "classe": class_name,
            "confiance": round(confidence, 2),
            "conseil": CATEGORIES[class_name]["conseil"],
            "image_path": image_path,
            "image_url": make_image_url(image_path),
            "toutes_proba": all_probabilities,
        })

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/historique", methods=["GET"])
@require_api_key
def historique():
    db = get_db()
    if db is None:
        return jsonify({
            "error": "MySQL non accessible",
            "message": "Assurez-vous que MySQL est lance",
        }), 500

    try:
        cur = db.cursor(dictionary=True)
        cur.execute(
            """
            SELECT
                cl.id,
                c.nom AS classe,
                cl.confiance,
                cl.image_path,
                DATE_FORMAT(cl.date_scan, '%Y-%m-%d %H:%i:%s') AS date_scan
            FROM classifications cl
            JOIN categories c ON c.id = cl.categorie_id
            ORDER BY cl.date_scan DESC
            LIMIT 50
            """
        )

        rows = cur.fetchall()

        for row in rows:
            row["image_url"] = make_image_url(row["image_path"])

        cur.close()
        db.close()

        return jsonify(rows)

    except Exception as e:
        db.close()
        return jsonify({"error": str(e)}), 500


@app.route("/stats", methods=["GET"])
@require_api_key
def stats():
    db = get_db()
    if db is None:
        return jsonify({
            "error": "MySQL non accessible",
            "message": "Assurez-vous que MySQL est lance",
        }), 500

    try:
        cur = db.cursor(dictionary=True)
        cur.execute(
            """
            SELECT
                c.nom AS classe,
                COUNT(*) AS total,
                ROUND(AVG(cl.confiance), 2) AS confiance_moyenne
            FROM classifications cl
            JOIN categories c ON c.id = cl.categorie_id
            GROUP BY c.nom
            ORDER BY total DESC
            """
        )

        rows = cur.fetchall()

        cur.close()
        db.close()

        return jsonify(rows)

    except Exception as e:
        db.close()
        return jsonify({"error": str(e)}), 500


@app.route("/delete/<int:scan_id>", methods=["DELETE"])
@require_api_key
def delete_scan(scan_id):
    db = get_db()
    if db is None:
        return jsonify({"error": "MySQL non accessible"}), 500

    try:
        cur = db.cursor(dictionary=True)

        cur.execute("SELECT image_path FROM classifications WHERE id = %s", (scan_id,))
        row = cur.fetchone()

        if row is None:
            cur.close()
            db.close()
            return jsonify({"status": "error", "message": "Scan non trouve"}), 404

        image_path = row["image_path"]

        cur.execute("DELETE FROM classifications WHERE id = %s", (scan_id,))
        db.commit()

        cur.close()
        db.close()

        if image_path and os.path.exists(image_path):
            os.remove(image_path)

        return jsonify({"status": "success", "message": "Scan supprime"}), 200

    except Exception as e:
        db.close()
        return jsonify({"status": "error", "message": str(e)}), 500


@app.errorhandler(404)
def not_found(e):
    return jsonify({
        "error": "Route non trouvee",
        "path": request.path,
        "method": request.method,
    }), 404


if __name__ == "__main__":
    print("=" * 50)
    print("Demarrage API EcoTri")
    print("=" * 50)

    init_categories()

    print("Serveur lance sur http://localhost:5000")
    print("Protection API active avec le header X-API-Key")
    app.run(host="0.0.0.0", port=5000, debug=True)
