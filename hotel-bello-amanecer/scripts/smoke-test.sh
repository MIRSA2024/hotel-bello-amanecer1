#!/usr/bin/env bash
# Prueba de humo: busca habitaciones, crea una reserva y consulta su estado.
# Local:  ./scripts/smoke-test.sh
# AWS:    ./scripts/smoke-test.sh https://<DNS-del-ALB>
set -euo pipefail
BASE=${1:-http://localhost:8080}
ENTRADA=$(date -d '+7 days' +%F 2>/dev/null || date -v+7d +%F)
SALIDA=$(date -d '+9 days' +%F 2>/dev/null || date -v+9d +%F)

echo "1) Disponibilidad ($ENTRADA a $SALIDA)"
HAB=$(curl -fsSk "$BASE/api/habitaciones/disponibles?entrada=$ENTRADA&salida=$SALIDA&huespedes=2")
echo "$HAB" | head -c 300; echo
ID=$(echo "$HAB" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

echo "2) Crear reserva en la habitación $ID"
RES=$(curl -fsSk -X POST "$BASE/api/reservas" -H 'Content-Type: application/json' -d "{
  \"habitacionId\": $ID, \"nombre\": \"Prueba Humo\", \"email\": \"prueba@example.com\",
  \"fechaEntrada\": \"$ENTRADA\", \"fechaSalida\": \"$SALIDA\", \"huespedes\": 2 }")
echo "$RES"
RID=$(echo "$RES" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

echo "3) Estado inicial y final (el consumidor tarda unos segundos)"
for i in 1 2 3 4 5 6; do
  ESTADO=$(curl -fsSk "$BASE/api/reservas/$RID" | grep -o '"estado":"[^"]*"' | cut -d'"' -f4)
  echo "   intento $i: $ESTADO"
  [ "$ESTADO" != "PENDIENTE" ] && break
  sleep 3
done
