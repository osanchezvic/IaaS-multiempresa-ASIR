-- Datos iniciales de ejemplo (opcional)
USE users_db;

-- Crear empresa administrador
INSERT IGNORE INTO empresas (id, nombre, descripcion, es_admin, estado) 
VALUES (1, 'admin', 'Cuenta administrador del sistema', 1, 'activa');

-- Crear usuario admin (password: admin123 encriptado con password_hash())
-- Para generar: php -r 'echo password_hash("admin123", PASSWORD_DEFAULT);'
INSERT IGNORE INTO usuarios (empresa_id, usuario, email, hash_password, es_admin, estado) 
VALUES (1, 'admin', 'admin@system.local', '$2y$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lm', 1, 'activo');

-- Ejemplos adicionales (comentados para no interferir)
-- INSERT INTO empresas (nombre, descripcion, es_admin) VALUES ('panaderia', 'Panadería Local', 0);
-- INSERT INTO usuarios (empresa_id, usuario, email, hash_password, es_admin) 
-- VALUES (2, 'gerente', 'gerente@panaderia.local', '$2y$10$...', 0);
-- INSERT INTO servicios_contratados (empresa_id, nombre_servicio, tipo, puerto, url_admin)
-- VALUES (2, 'wordpress', 'cms', 8001, 'http://panaderia-wordpress:80/wp-admin');
