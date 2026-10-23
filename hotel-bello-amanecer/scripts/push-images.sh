#!/usr/bin/env bash
# Construye las 4 imágenes y las publica en Amazon ECR (Código 4 del informe).
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."

export AWS_REGION=${AWS_REGION:-us-east-1}
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
export TAG=${TAG:-$(git rev-parse --short HEAD 2>/dev/null || echo "local-$(date +%Y%m%d%H%M)")}
echo "Cuenta: $ACCOUNT_ID  Región: $AWS_REGION  Etiqueta: $TAG"

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR"

for svc in frontend-web api-reservas consumer-pagos servicio-notificaciones; do
  # Las etiquetas en ECR son inmutables: si ya existe, no se vuelve a subir
  if aws ecr describe-images --region "$AWS_REGION" --repository-name "hba/$svc" \
       --image-ids imageTag="$TAG" >/dev/null 2>&1; then
    echo "hba/$svc:$TAG ya existe en ECR, se omite."
    continue
  fi
  docker build -t "$ECR/hba/$svc:$TAG" "./services/$svc"
  docker push "$ECR/hba/$svc:$TAG"
done
echo "$TAG" > .last-image-tag
echo "Imágenes publicadas con la etiqueta $TAG"
