CREATE DATABASE IF NOT EXISTS waste_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE waste_db;

CREATE TABLE IF NOT EXISTS categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(50) NOT NULL UNIQUE,
  conseil VARCHAR(255) NOT NULL,
  couleur VARCHAR(50) NOT NULL,
  bac VARCHAR(50) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS classifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  categorie_id INT NOT NULL,
  confiance DECIMAL(5,2) NOT NULL,
  date_scan DATETIME NOT NULL,
  image_path VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_classifications_categories
    FOREIGN KEY (categorie_id)
    REFERENCES categories(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  INDEX idx_classifications_date_scan (date_scan),
  INDEX idx_classifications_categorie_id (categorie_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
