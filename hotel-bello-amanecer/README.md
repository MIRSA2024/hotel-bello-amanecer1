# Hotel Bello Amanecer — reservas en la nube (AWS)

Sistema de reservas de habitaciones con arquitectura de microservicios y mensajería asíncrona, desplegado en AWS
(cuenta educativa AWS Academy, región `us-east-1`). Proyecto del curso Planeamiento Estratégico de las TIC (UTP).
El informe técnico está en [`docs/APF_1.docx`](docs/APF_1.docx).

```
Huésped ──HTTPS──► ALB ──► frontend-web (Angular + Nginx)
                      └──► api-reservas (Spring Boot) ──► RDS PostgreSQL
                                   │ RESERVA_CREADA
                                   ▼
                              SQS q-reservas ──► consumer-pagos ──► SQS q-notificaciones ──► servicio-notificaciones
                                   (DLQ tras 5 intentos)                                    (correo / log)
```

## Estructura

| Carpeta | Contenido |
|---|---|
| `services/` | Los 4 servicios con su `Dockerfile` (frontend-web, api-reservas, consumer-pagos, servicio-notificaciones) |
| `infra/` | Terraform por capa: `network`, `security`, `data`, `compute` (y `local/` con la config del emulador SQS) |
| `ecs/` | Definiciones de tarea (JSON) y scripts para crear/eliminar los servicios ECS |
| `scripts/` | `push-images.sh` (ECR), `smoke-test.sh` (prueba de humo) y `setup-codespaces.sh` |
| `docs/` | Informe, guía paso a paso, evidencias (capturas) y el script que las inserta en el informe |

## Ejecución local (sin AWS)

Requisitos: Docker Desktop.

```bash
cp .env.example .env          # y poner una clave local de prueba
docker compose up -d --build
docker compose ps             # todos "healthy" / "Up"
./scripts/smoke-test.sh       # crea una reserva y ve cómo pasa de PENDIENTE a CONFIRMADA
```

Frontend: http://localhost:8081 · API: http://localhost:8080/api · Salud: http://localhost:8080/actuator/health

Para apagar: `docker compose down` (agrega `-v` para borrar también la base de datos).

## Despliegue en AWS

Requisitos: AWS CLI v2, Terraform ≥ 1.5, Docker, Git Bash (Windows) o cualquier shell bash, y las credenciales
temporales del laboratorio en `~/.aws/credentials`.

```bash
./infra/deploy.sh               # network > security > data > compute (RDS Multi-AZ tarda ~15 min)
./scripts/push-images.sh        # construye y publica las 4 imágenes en ECR
./ecs/deploy-services.sh        # registra tareas y crea los 4 servicios; imprime la URL del ALB
./scripts/smoke-test.sh https://<DNS-del-ALB>
```

Limpieza (importante: NAT, ALB y RDS consumen créditos mientras existan):

```bash
./ecs/destroy-services.sh && ./infra/destroy.sh
```

Opciones de laboratorio (se pasan con `-var` a `terraform apply` del módulo `data`):
`db_multi_az=false` si el laboratorio rechaza Multi-AZ, `use_managed_master_password=false` si no permite el
secreto administrado por RDS.

La guía completa, con las capturas que pide el informe, está en [`docs/GUIA_PASO_A_PASO.md`](docs/GUIA_PASO_A_PASO.md).

## Convenciones

- Ramas: `main` (protegida), `develop`, `feature/<descripcion>`, `fix/<descripcion>`.
- Commits: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `infra:`).
- Secretos: nunca se versionan (`.env`, `*.tfstate`, `*.tfvars`). Solo `.env.example` sin valores reales.
