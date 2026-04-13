```mermaid
flowchart TD

A0([Inicio]) --> A1[Leer parámetros: EMPRESA y SERVICIO]
A1 --> A2{¿Parámetros vacíos?}

A2 -- Sí --> A2A[Log error: parámetros insuficientes]
A2A --> A2B[Mostrar uso]
A2B --> A2C([Salir 1])

A2 -- No --> A3[init_log]

%% Validaciones pre-deploy
A3 --> A4[validar_pre_deploy]
A4 -->|Fallo| A4A[Log failed]
A4A --> A4B([Salir 1])
A4 -->|OK| A5[Construir rutas SERVICIO_DIR y COMPOSE_FILE]

%% Comprobación de existencia
A5 --> A6{¿docker-compose.yml existe?}
A6 -- No --> B0[Continuar con deploy nuevo]
A6 -- Sí --> A7[Log warn: servicio ya existe]

A7 --> A8{¿docker compose ps indica healthy/running?}
A8 -- Sí --> A8A[Log success: ya activo]
A8A --> A8B([Salir 0])

A8 -- No --> A9[Levantar servicio existente: docker compose up -d]
A9 --> A10[wait_container_healthy 30s]

A10 -->|OK| A10A[Log success: reiniciado]
A10A --> A10B([Salir 0])

A10 -->|Fallo| A10C[Log error: no se pudo levantar]
A10C --> A10D([Salir 1])

%% Nuevo deploy
B0 --> B1{¿Directorio existe y tiene restos?}
B1 -- Sí --> B1A[crear_backup]
B1A --> B1B[Log warn si falla]
B1 -- No --> B2[mkdir -p SERVICIO_DIR]
B1B --> B2

B2 --> B3[Generar credenciales y valores]

%% Asignación de puerto
B3 --> B4[asignar_puerto]
B4 -->|Fallo| B4A[Log failed: no se pudo asignar puerto]
B4A --> B4B([Salir 1])

B4 -->|OK| B5[Generar DB_NAME, DB_USER, DB_PASSWORD, ADMIN_USER, ADMIN_PASSWORD, JWT_SECRET]

%% Guardar credenciales
B5 --> B6[Construir JSON con jq]
B6 --> B7[guardar_credenciales]
B7 --> B7A[Log success: credenciales guardadas]
