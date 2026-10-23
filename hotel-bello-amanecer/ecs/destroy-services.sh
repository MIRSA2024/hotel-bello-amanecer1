#!/usr/bin/env bash
# Elimina los servicios ECS (hacerlo ANTES de infra/destroy.sh).
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
export AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER=$(terraform -chdir=infra/compute output -raw cluster_name)
for s in hba-frontend-web hba-api-reservas hba-consumer-pagos hba-servicio-notificaciones; do
  aws ecs update-service --region "$AWS_REGION" --cluster "$CLUSTER" --service "$s" --desired-count 0 >/dev/null 2>&1 || true
  aws ecs delete-service --region "$AWS_REGION" --cluster "$CLUSTER" --service "$s" --force >/dev/null 2>&1 || true
  echo "Servicio $s eliminado (o no existía)"
done
