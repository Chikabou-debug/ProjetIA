import cv2
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications.efficientnet import preprocess_input


# Chargement du modele sauvegarde
MODEL_PATH = "models/best_model_b3_20260512_002223.keras"
IMG_SIZE = (300, 300)

model = tf.keras.models.load_model(MODEL_PATH)
CLASSES = ["biological", "metal", "paper", "plastic"]

# Couleurs par classe (BGR)
COLORS = {
    "biological": (0, 200, 0),    # vert
    "metal":      (200, 200, 0),  # cyan
    "paper":      (0, 165, 255),  # orange
    "plastic":    (0, 0, 255),    # rouge
}


def predict_frame(frame):
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    img = cv2.resize(frame_rgb, IMG_SIZE)
    img = np.expand_dims(img, axis=0)
    img = preprocess_input(img.astype(np.float32))

    preds = model.predict(img, verbose=0)[0]
    class_idx = np.argmax(preds)
    class_name = CLASSES[class_idx]
    confidence = preds[class_idx] * 100

    return class_name, confidence


# Lancement de la camera
cap = cv2.VideoCapture(0)  # 0 = webcam principale

print("Camera lancee - appuie sur 'q' pour quitter")

while True:
    ret, frame = cap.read()
    if not ret:
        break

    class_name, confidence = predict_frame(frame)
    color = COLORS[class_name]

    # Affichage sur l'image
    label = f"{class_name} ({confidence:.1f}%)"
    cv2.rectangle(frame, (10, 10), (400, 70), color, -1)
    cv2.putText(
        frame,
        label,
        (20, 50),
        cv2.FONT_HERSHEY_SIMPLEX,
        1.2,
        (255, 255, 255),
        2,
    )

    cv2.imshow("Tri des dechets", frame)

    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
