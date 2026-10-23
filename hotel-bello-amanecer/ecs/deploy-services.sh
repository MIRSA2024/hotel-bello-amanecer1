#!/usr/bin/env bash
# Registra las definiciones de tarea (ecs/*.json) y crea o actualiza los 4 servicios ECS.
# Requisitos: infraestructura aplicada (infra/deploy.sh) e imágenes publicadas (scripts/push-images.sh).
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."

export AWS_REGION=${AWS_REGION:-us-east-1}
export IMAGE_TAG=${IMAGE_TAG:-$(cat .last-image-tag 2>/dev/null || git rev-parse --short HEAD)}
out() { terraform -chdir="infra/$1" output -raw "$2"; }

export ECR_REGISTRY=$(out compute ecr_registry)
export LAB_ROLE_ARN=$(out compute lab_role_arn)
export DB_ENDPOINT=$(out data db_endpoint)
export DB_SECRET_ARN=$(out data db_secret_arn)
export MAIL_SECRET_ARN=$(out data mail_secret_arn)
CLUSTER=$(out compute cluster_name)
CP=$(out compute capacity_provider)
TG_FRONT=$(out compute tg_frontend_arn)
TG_API=$(out compute tg_api_arn)

render() { # sustituye ${VARIABLES} del JSON sin depender de envsubst
  sed -e "s|\${ECR_REGISTRY}|$ECR_REGISTRY|g" -e "s|\${IMAGE_TAG}|$IMAGE_TAG|g" \
      -e "s|\${LAB_ROLE_ARN}|$LAB_ROLE_ARN|g" -e "s|\${DB_ENDPOINT}|$DB_ENDPOINT|g" \
      -e "s|\${DB_SECRET_ARN}|$DB_SECRET_ARN|g" -e "s|\${MAIL_SECRET_ARN}|$MAIL_SECRET_ARN|g" \
      -e "s|\${AWS_REGION}|$AWS_REGION|g" "$1"
}

# nombre | desired | target group | puerto del contenedor
SERVICES=(
  "frontend-web|2|$TG_FRONT|8080"
  "api-reservas|2|$TG_API|8080"
  "consumer-pagos|1||"
  "servicio-notificaciones|1||"
)

for entry in "${SERVICES[@]}"; do
  IFS='|' read -r name desired tg port <<<"$entry"
  render "ecs/$name.json" > ".rendered-$name.json"
  aws ecs register-task-definition --region "$AWS_REGION" \
    --cli-input-json "file://.rendered-$name.json" --query 'taskDefinition.taskDefinitionArn' --output text
  rm -f ".rendered-$name.json"

  status=$(aws ecs describe-services --region "$AWS_REGION" --cluster "$CLUSTER" \
    --services "hba-$name" --query 'services[0].status' --output text 2>/dev/null || echo NONE)
  if [ "$status" = "ACTIVE" ]; then
    aws ecs update-service --region "$AWS_REGION" --cluster "$CLUSTER" --service "hba-$name" \
      --task-definition "hba-$name" --desired-count "$desired" --force-new-deployment >/dev/null
    echo "Servicio hba-$name actualizado"
  else
    lb_args=()
    if [ -n "$tg" ]; then
      lb_args=(--load-balancers "targetGroupArn=$tg,containerName=$name,containerPort=$port"
               --health-check-grace-period-seconds 120)
    fi
    aws ecs create-service --region "$AWS_REGION" --cluster "$CLUSTER" --service-name "hba-$name" \
      --task-definition "hba-$name" --desired-count "$desired" \
      --capacity-provider-strategy "capacityProvider=$CP,weight=1" \
      --deployment-configuration "minimumHealthyPercent=50,maximumPercent=200" \
      "${lb_args[@]}" >/dev/null
    echo "Servicio hba-$name creado"
  fi
done

echo
echo "Esperando a que los servicios se estabilicen (puede tardar 3-6 minutos)..."
aws ecs wait services-stable --region "$AWS_REGION" --cluster "$CLUSTER" \
  --services hba-frontend-web hba-api-reservas hba-consumer-pagos hba-servicio-notificaciones || \
  echo "Aún no están estables: revisa la consola de ECS (pestaña Eventos)."
echo "URL de la aplicación: https://$(out compute alb_dns_name)"
