#!/usr/bin/env bash
set -euo pipefail

API_URL="${API_URL:-http://localhost:4000}"
ACCOUNT_ID="${ACCOUNT_ID:-1}"
AMOUNT="${AMOUNT:-10.00}"
REQUESTS="${REQUESTS:-20}"
ACTION="${ACTION:-withdraw}"

if [[ "$ACTION" != "deposit" && "$ACTION" != "withdraw" ]]; then
  echo "ACTION must be deposit or withdraw" >&2
  exit 1
fi

echo "Firing $REQUESTS concurrent $ACTION requests of $AMOUNT against account $ACCOUNT_ID"

for i in $(seq 1 "$REQUESTS"); do
  (
    status="$(
      curl -s -o /tmp/financial-control-stress-"$i".json -w "%{http_code}" \
        -X POST "$API_URL/api/accounts/$ACCOUNT_ID/$ACTION" \
        -H "content-type: application/json" \
        -H "x-idempotency-key: stress-$ACTION-$(date +%s)-$i" \
        -d "{\"amount\":\"$AMOUNT\"}"
    )"

    echo "request=$i status=$status body=$(cat /tmp/financial-control-stress-"$i".json)"
  ) &
done

wait

echo "Final account snapshot:"
curl -s "$API_URL/api/accounts/$ACCOUNT_ID"
echo
