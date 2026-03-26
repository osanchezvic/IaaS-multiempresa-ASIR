-- Esquema centralizado de usuarios y empresas
-- Base de datos para autenticación multi-tenant

CREATE DATABASE IF NOT EXISTS users_db;
USE users_db;

-- Tabla de empresas
CREATE TABLE IF NOT EXISTS empresas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(255) NOT NULL UNIQUE,
    descripcion TEXT,
    es_admin BOOLEAN DEFAULT 0,
    estado VARCHAR(20) DEFAULT 'activa',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id INT PRIMARY KEY AUTO_INCREMENT,
    empresa_id INT NOT NULL,
    usuario VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    hash_password VARCHAR(255) NOT NULL,
    es_admin BOOLEAN DEFAULT 0,
    estado VARCHAR(20) DEFAULT 'activo',
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso TIMESTAMP NULL,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    UNIQUE KEY unique_usuario_empresa (empresa_id, usuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de servicios contratados por empresa
CREATE TABLE IF NOT EXISTS servicios_contratados (
    id INT PRIMARY KEY AUTO_INCREMENT,
    empresa_id INT NOT NULL,
    nombre_servicio VARCHAR(100) NOT NULL,
    tipo VARCHAR(50),
    puerto INT,
    url_admin VARCHAR(255),
    estado VARCHAR(20) DEFAULT 'activo',
    fecha_contratacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE CASCADE,
    UNIQUE KEY unique_servicio_empresa (empresa_id, nombre_servicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de logs de acceso
CREATE TABLE IF NOT EXISTS access_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT,
    empresa_id INT,
    accion VARCHAR(100),
    ip_address VARCHAR(45),
    user_agent TEXT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índices para optimización
CREATE INDEX idx_empresa_usuario ON usuarios(empresa_id);
CREATE INDEX idx_empresa_servicios ON servicios_contratados(empresa_id);
CREATE INDEX idx_acceso_fecha ON access_logs(fecha);

-- Data de ejemplo (opcional, comentado)
-- INSERT INTO empresas (nombre, descripcion, es_admin) VALUES ('admin', 'Cuenta administrador', 1);
-- INSERT INTO usuarios (empresa_id, usuario, email, hash_password, es_admin) VALUES 
-- (1, 'admin', 'admin@example.com', '$2y$10$...', 1);
