#!/usr/bin/env bash
# Despliega la infraestructura en el orden network > security > data > compute.
# Uso:  ./infra/deploy.sh            (los cuatro módulos)
#       ./infra/deploy.sh network    (solo uno)
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"

MODULES=("$@")
[ ${#MODULES[@]} -eq 0 ] && MODULES=(network security data compute)

for m in "${MODULES[@]}"; do
  echo
  echo "================ $m ================"
  terraform -chdir="$m" init -input=false
  terraform -chdir="$m" plan -input=false -out=tfplan
  terraform -chdir="$m" apply -input=false tfplan
done
echo
echo "Listo. Siguiente paso: ./scripts/push-images.sh y luego ./ecs/deploy-services.sh"
