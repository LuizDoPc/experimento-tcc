#!/bin/bash

NAMESPACE="monitoring"

LABELS=("gohttptest" "gogrpctest" "javahttptest" "javagrpctest")

PORTS=("8081:8080" "8084:8080,50052:50001" "8080:8080" "8083:8080,50051:50051")

port_forward() {
  local pod_label="$1"
  local port_mappings="$2"
  
  local pod_name=$(kubectl get pods -n $NAMESPACE -l "app.kubernetes.io/instance=$pod_label" -o jsonpath="{.items[0].metadata.name}")
  
  if [ -z "$pod_name" ]; then
    echo "Nenhum Pod encontrado com o label app.kubernetes.io/instance=$pod_label no namespace $NAMESPACE."
    exit 1
  fi
  
  for port_mapping in $(echo "$port_mappings" | tr "," " "); do
    kubectl port-forward -n $NAMESPACE $pod_name $port_mapping &
  done
}

for ((i=0; i<${#LABELS[@]}; i++)); do
  LABEL="${LABELS[$i]}"
  PORT_MAPPING="${PORTS[$i]}"
  
  port_forward "$LABEL" "$PORT_MAPPING"
done

wait
