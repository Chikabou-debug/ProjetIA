import os
import random
import shutil


# Configuration
SOURCE_DIR = "."
OUTPUT_DIR = "dataset_split"
CLASSES = ["biological", "metal", "paper", "plastic"]

TRAIN_RATIO = 0.70
VAL_RATIO = 0.15
TEST_RATIO = 0.15

SEED = 42
random.seed(SEED)


# Creation des dossiers
for split in ["train", "val", "test"]:
    for cls in CLASSES:
        os.makedirs(os.path.join(OUTPUT_DIR, split, cls), exist_ok=True)


# Division et copie
for cls in CLASSES:
    images = os.listdir(os.path.join(SOURCE_DIR, cls))
    images = [
        filename
        for filename in images
        if filename.lower().endswith((".jpg", ".jpeg", ".png", ".webp"))
    ]
    random.shuffle(images)

    total = len(images)
    n_train = int(total * TRAIN_RATIO)
    n_val = int(total * VAL_RATIO)

    splits = {
        "train": images[:n_train],
        "val": images[n_train:n_train + n_val],
        "test": images[n_train + n_val:],
    }

    for split, files in splits.items():
        for filename in files:
            src = os.path.join(SOURCE_DIR, cls, filename)
            dst = os.path.join(OUTPUT_DIR, split, cls, filename)
            shutil.copy2(src, dst)

    print(
        f"{cls:12s} -> train:{len(splits['train'])} "
        f"| val:{len(splits['val'])} | test:{len(splits['test'])}"
    )

print("Division terminee !")
