flowchart TD

A0([Inicio]) --> A1[Leer parámetros: EMPRESA y SERVICIO]
A1 --> A2{¿Parámetros vacíos?}
A2 -- Sí --> A2A[Log error: parámetros insuficientes] --> A2B[Mostrar uso] --> A2C([Salir 1])
A2 -- No --> A3[init_log]

%% Validaciones pre-deploy
A3 --> A4[validar_pre_deploy]
A4 -->|Fallo| A4A[Log failed] --> A4B([Salir 1])
A4 -->|OK| A5[Construir rutas SERVICIO_DIR y COMPOSE_FILE]

%% Comprobación de existencia
A5 --> A6{¿docker-compose.yml existe?}
A6 -- No --> B0[Continuar con deploy nuevo]
A6 -- Sí --> A7[Log warn: servicio ya existe]
A7 --> A8{¿docker compose ps indica healthy/running?}
A8 -- Sí --> A8A[Log success: ya activo] --> A8B([Salir 0])
A8 -- No --> A9[Levantar servicio existente: docker compose up -d]
A9 --> A10[wait_container_healthy 30s]
A10 -->|OK| A10A[Log success: reiniciado] --> A10B([Salir 0])
A10 -->|Fallo| A10C[Log error: no se pudo levantar] --> A10D([Salir 1])

%% Nuevo deploy
B0 --> B1{¿Directorio existe y tiene restos?}
B1 -- Sí --> B1A[crear_backup] --> B1B[Log warn si falla]
B1 -- No --> B2[mkdir -p SERVICIO_DIR]
B1B --> B2
B2 --> B3[Generar credenciales y valores]

%% Asignación de puerto
B3 --> B4[asignar_puerto]
B4 -->|Fallo| B4A[Log failed: no se pudo asignar puerto] --> B4B([Salir 1])
B4 -->|OK| B5[Generar DB_NAME, DB_USER, DB_PASSWORD, ADMIN_USER, ADMIN_PASSWORD, JWT_SECRET]

%% Guardar credenciales
B5 --> B6[Construir JSON con jq]
B6 --> B7[guardar_credenciales]
B7 --> B7A[Log success: credenciales guardadas]

%% Registrar en BD
B7A --> C1[db_register_empresa]
C1 -->|Fallo| C1A[Log debug: ya existe]
C1 --> C2[crear_usuario_admin]
C2 -->|Fallo| C2A[Log debug: ya existe o BD no disponible]
C2 --> C3[db_register_servicio]
C3 -->|Fallo| C3A[Log error: no se pudo registrar] --> C3B([Salir 1])
C3 -->|OK| D0[Procesar templates]

%% Templates
D0 --> D1{¿Existe docker-compose.tpl?}
D1 -- No --> D1A[Log error: falta template] --> D1B([Salir 1])
D1 -- Sí --> D2[Generar docker-compose.yml con sed]
D2 --> D3{¿Existe env.tpl?}
D3 -- Sí --> D3A[Generar .env]
D3 -- No --> D4[Continuar]
D3A --> D4

%% Validar templates
D4 --> D5[validar_compose_template]
D5 -->|Fallo| D5A[Log failed] --> D5B([Salir 1])
D5 --> D6[validar_env_template]
D6 -->|Fallo| D6A[Log failed] --> D6B([Salir 1])
D6 --> E0[Crear red Docker]

%% Red Docker
E0 --> E1{¿Red existe?}
E1 -- No --> E1A[docker network create]
E1 -- Sí --> E1B[Log debug: ya existe]
E1A --> E2[Desplegar en Docker]
E1B --> E2

%% Docker compose up
E2 --> E3[docker compose up -d]
E3 -->|Fallo| E3A[Log failed] --> E3B([Salir 1])
E3 --> E4[wait_container_healthy 60s]

%% Post-deploy
E4 -->|Fallo| E4A[Log warn: no llegó a healthy]
E4 --> F0[validar_post_deploy]
F0 -->|Fallo| F0A[Log warn: fallos post-deploy]
F0 --> G0[Obtener IP local]
G0 --> G1[Construir URL dashboard]
G1 --> G2[Mostrar resumen final]
G2 --> Z([Salir 0])
