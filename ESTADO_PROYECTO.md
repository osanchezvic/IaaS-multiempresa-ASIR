# Estado del Proyecto

**Status:** LISTO PARA DEFENSA ASIR

---

## Funcionalidades implementadas

- **Desplegar servicios** (`deploy.sh`)
- **Listar servicios** (`list.sh` - tabla/JSON/CSV)
- **Obtener credenciales** (`get-credentials.sh`)
- **Eliminar servicios** (`destroy.sh` - con backup automático)
- **Validación automática de dependencias** (WordPress → MariaDB)
- **Gestión de puertos sin colisiones**
- **Credenciales seguras** (permisos 600)
- **Backups automáticos** antes de eliminar
- **Suite de tests** (8 tests automáticos)

---

## Métricas

| Métrica | Valor |
|---------|-------|
| Servicios en catálogo | 14 |
| Scripts principales | 5 |
| Módulos reutilizables | 5 |
| Tests automáticos | 8/8 PASS |
| Servicios infraestructura | 8 |

---

## Flujo de uso

```bash
# 1. Desplegar
./deploy.sh acme wordpress

# 2. Ver servicios
./list.sh acme

# 3. Obtener credenciales
./get-credentials.sh acme wordpress

# 4. Eliminar (con backup)
./destroy.sh acme wordpress
```

---

## Testing

```bash
cd scripts
./test.sh
# Resultado: 8 PASS, 0 FAIL
```

---

## Checklist defensa

- [x] Deploy funciona con dependencias automáticas
- [x] List muestra servicios en múltiplos formatos
- [x] Get-credentials muestra datos correctos
- [x] Destroy elimina con backup
- [x] Base de datos mantiene integridad
- [x] Credenciales se guardan y recuperan
- [x] Tests pasan 8/8