-- Base de datos para usuarios multiempresa
-- Tabla de usuarios: empresa, usuario, hash_password (bcrypt), rol

CREATE DATABASE IF NOT EXISTS users_db;

USE users_db;

CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    empresa VARCHAR(50) NOT NULL,
    usuario VARCHAR(50) NOT NULL,
    hash_password VARCHAR(255) NOT NULL,  -- bcrypt hash
    rol ENUM('admin', 'user') DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_empresa_usuario (empresa, usuario)
);

-- Usuario admin por defecto para cada empresa
-- Se insertará al crear empresa