# Backups - Sistema simple de copias de seguridad

## Propósito

Hacer backup y restaurar servicios de empresas de forma sencilla.

## Estructura

- **config.env**: Configuración (retención, ruta base)
- **backup.sh**: Crear backup de un servicio
- **restore.sh**: Restaurar desde backup existente
- **cleanup.sh**: Limpiar backups antiguos (por cron)

## Uso

### 1. Hacer backup

```bash
./backup.sh <empresa> <servicio>
./backup.sh acme wordpress
```

Crea: `/srv/backups/acme/wordpress/backup_20260326_120000.tar.gz`

### 2. Listar backups

```bash
ls -lh /srv/backups/acme/wordpress/
```

### 3. Restaurar último backup

```bash
./restore.sh acme wordpress
```

### 4. Restaurar backup específico

```bash
./restore.sh acme wordpress 20260326_120000
```

### 5. Limpiar backups antiguos

```bash
./cleanup.sh
```

Elimina backups más viejos de 30 días (configurable en `config.env`).

## Integración con Cron

Ejecutar limpieza automática cada madrugada:

```bash
# /etc/cron.d/backups-cleanup
0 2 * * * /scripts/infra/backups/cleanup.sh
```

## Integración con deploy.sh

En `deploy.sh`, antes de destruir un servicio:

```bash
# Hace backup antes de destroy
/scripts/infra/backups/backup.sh "$empresa" "$servicio"
```

## Archivo de auditoría

```bash
tail -f /srv/backups/backups.log
```

Registra: OK/FAIL, empresa/servicio, archivo, tamaño, timestamp.

## Notas ASIR

- Scripts simples: `tar`, `docker`, `find`, `ls`
- Sin dependencias externas
- Backups comprimidos (gzip) para ahorrar espacio
- Log de auditoría en txt plano
- Permisos: solo lectura de archivos antiguos antes de eliminar
