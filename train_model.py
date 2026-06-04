import os
from datetime import datetime

import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import tensorflow as tf
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.utils.class_weight import compute_class_weight
from tensorflow.keras import Model, layers
from tensorflow.keras.applications import EfficientNetB3
from tensorflow.keras.applications.efficientnet import preprocess_input
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
from tensorflow.keras.preprocessing.image import ImageDataGenerator


# 1. Configuration
TRAIN_DIR = "dataset_split/train"
VAL_DIR = "dataset_split/val"
TEST_DIR = "dataset_split/test"

IMG_SIZE = (300, 300)
BATCH = 32
CLASSES = ["biological", "metal", "paper", "plastic"]

RUN_ID = datetime.now().strftime("%Y%m%d_%H%M%S")
OUTPUT_DIR = "models"
MODEL_PATH = os.path.join(OUTPUT_DIR, f"best_model_b3_{RUN_ID}.keras")
CONFUSION_MATRIX_PATH = os.path.join(OUTPUT_DIR, f"confusion_matrix_b3_{RUN_ID}.png")
LEARNING_CURVES_PATH = os.path.join(OUTPUT_DIR, f"courbes_apprentissage_b3_{RUN_ID}.png")

os.makedirs(OUTPUT_DIR, exist_ok=True)


# 2. Augmentation des donnees
# Les valeurs restent realistes pour une camera de tri de dechets.
train_gen = ImageDataGenerator(
    preprocessing_function=preprocess_input,
    horizontal_flip=True,
    rotation_range=20,
    zoom_range=0.2,
    width_shift_range=0.1,
    height_shift_range=0.1,
    brightness_range=[0.7, 1.3],
    shear_range=0.1,
    channel_shift_range=10.0,
)

val_test_gen = ImageDataGenerator(
    preprocessing_function=preprocess_input,
)


# 3. Chargement des images
train_data = train_gen.flow_from_directory(
    TRAIN_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH,
    class_mode="categorical",
    classes=CLASSES,
)

val_data = val_test_gen.flow_from_directory(
    VAL_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH,
    class_mode="categorical",
    shuffle=False,
    classes=CLASSES,
)

test_data = val_test_gen.flow_from_directory(
    TEST_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH,
    class_mode="categorical",
    shuffle=False,
    classes=CLASSES,
)

print("Classes detectees :", train_data.class_indices)
print(f"Train : {train_data.samples} | Val : {val_data.samples} | Test : {test_data.samples}\n")


# 4. Calcul des poids par classe
classes_array = np.array(train_data.classes)
unique_classes = np.unique(classes_array)
class_weights = compute_class_weight(
    class_weight="balanced",
    classes=unique_classes,
    y=classes_array,
)
class_weight_dict = dict(zip(unique_classes, class_weights))

print("Poids par classe :")
for idx, cls in enumerate(CLASSES):
    print(f"  {cls:12s} -> {class_weight_dict[idx]:.4f}")
print()


# 5. Modele EfficientNetB3
base_model = EfficientNetB3(
    weights="imagenet",
    include_top=False,
    input_shape=(300, 300, 3),
)
base_model.trainable = False

inputs = tf.keras.Input(shape=(300, 300, 3))
x = base_model(inputs, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.BatchNormalization()(x)
x = layers.Dense(512, activation="relu")(x)
x = layers.Dropout(0.5)(x)
x = layers.Dense(256, activation="relu")(x)
x = layers.Dropout(0.3)(x)
outputs = layers.Dense(len(CLASSES), activation="softmax")(x)

model = Model(inputs, outputs)
model.summary()


# 6. Callbacks
callbacks = [
    EarlyStopping(
        patience=7,
        restore_best_weights=True,
        monitor="val_accuracy",
    ),
    ModelCheckpoint(
        MODEL_PATH,
        save_best_only=True,
        monitor="val_accuracy",
    ),
    ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.5,
        patience=3,
        min_lr=1e-7,
        verbose=1,
    ),
]


# 7. Phase 1 : entrainement des couches ajoutees
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss="categorical_crossentropy",
    metrics=["accuracy"],
)

print("Phase 1 : entrainement des couches ajoutees")
history1 = model.fit(
    train_data,
    validation_data=val_data,
    epochs=15,
    callbacks=callbacks,
    class_weight=class_weight_dict,
)


# 8. Phase 2 : fine-tuning
base_model.trainable = True
for layer in base_model.layers[:-40]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
    loss="categorical_crossentropy",
    metrics=["accuracy"],
)

print("\nPhase 2 : fine-tuning")
history2 = model.fit(
    train_data,
    validation_data=val_data,
    epochs=20,
    callbacks=callbacks,
    class_weight=class_weight_dict,
)


# 9. Evaluation finale
print("\nEvaluation finale")
loss, accuracy = model.evaluate(test_data)
print(f"Test Accuracy : {accuracy * 100:.2f}%")

y_pred = np.argmax(model.predict(test_data), axis=1)
y_true = test_data.classes

print("\n", classification_report(y_true, y_pred, target_names=CLASSES, zero_division=0))

cm = confusion_matrix(y_true, y_pred)
plt.figure(figsize=(8, 6))
sns.heatmap(cm, annot=True, fmt="d", cmap="Blues", xticklabels=CLASSES, yticklabels=CLASSES)
plt.title("Matrice de confusion - EfficientNetB3")
plt.ylabel("Reel")
plt.xlabel("Predit")
plt.tight_layout()
plt.savefig(CONFUSION_MATRIX_PATH)
plt.show()


# 10. Courbes d'apprentissage
acc = history1.history["accuracy"] + history2.history["accuracy"]
val_acc = history1.history["val_accuracy"] + history2.history["val_accuracy"]
loss_h = history1.history["loss"] + history2.history["loss"]
val_loss = history1.history["val_loss"] + history2.history["val_loss"]

plt.figure(figsize=(12, 4))
plt.subplot(1, 2, 1)
plt.plot(acc, label="Train")
plt.plot(val_acc, label="Validation")
plt.axvline(
    x=len(history1.history["accuracy"]) - 1,
    color="red",
    linestyle="--",
    label="Debut fine-tuning",
)
plt.title("Accuracy")
plt.legend()

plt.subplot(1, 2, 2)
plt.plot(loss_h, label="Train")
plt.plot(val_loss, label="Validation")
plt.axvline(
    x=len(history1.history["loss"]) - 1,
    color="red",
    linestyle="--",
    label="Debut fine-tuning",
)
plt.title("Loss")
plt.legend()

plt.tight_layout()
plt.savefig(LEARNING_CURVES_PATH)
plt.show()

print(f"\nTermine ! Modele sauvegarde dans {MODEL_PATH}")
