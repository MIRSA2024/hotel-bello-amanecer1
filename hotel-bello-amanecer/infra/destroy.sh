#!/usr/bin/env bash
# Destruye todo en orden inverso (compute > data > security > network).
# Antes hay que borrar los servicios ECS:  ./ecs/destroy-services.sh
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"

# 1) compute
terraform -chdir=compute destroy -input=false -auto-approve

# 2) data: primero se desactiva la protección contra borrado y el snapshot final
terraform -chdir=data apply -input=false -auto-approve \
  -var="db_deletion_protection=false" -var="db_skip_final_snapshot=true"
terraform -chdir=data destroy -input=false -auto-approve \
  -var="db_deletion_protection=false" -var="db_skip_final_snapshot=true"

# 3) security y 4) network
terraform -chdir=security destroy -input=false -auto-approve
terraform -chdir=network destroy -input=false -auto-approve
echo "Infraestructura destruida."
