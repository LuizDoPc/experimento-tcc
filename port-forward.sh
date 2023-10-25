#!/bin/bash

NAMESPACE="monitoring"

port_forward() {
  local app_name="$1"
  local label_key="app.kubernetes.io/instance"
  local port_mapping=""

  case "$app_name" in
    "gohttptest")
      port_mapping="8081:8080"
      ;;
    "gogrpctest")
      port_mapping="8084:8080,50052:50001"
      ;;
    "javahttptest")
      port_mapping="8080:8080"
      ;;
    "javagrpctest")
      port_mapping="8083:8080,50051:50059"
      ;;
    "grafana")
      port_mapping="3000:3000"
      label_key="app.kubernetes.io/name"
      ;;
    *)
      echo "Aplicação desconhecida: $app_name"
      exit 1
      ;;
  esac

  local pod_name=$(kubectl get pods -n $NAMESPACE -l "$label_key=$app_name" -o jsonpath="{.items[0].metadata.name}")

  if [ -z "$pod_name" ]; then
    echo "Nenhum Pod encontrado com o label $label_key=$app_name no namespace $NAMESPACE."
    exit 1
  fi

  for port_mapping in $(echo "$port_mapping" | tr "," " "); do
    local local_port=$(echo "$port_mapping" | cut -d ':' -f 1)
    echo "Verificando se o processo está ouvindo na porta $local_port..."
    local process_id=$(lsof -t -i :$local_port)

    if [ -n "$process_id" ]; then
      echo "Processo encontrado na porta $local_port. Encerrando..."
      kill -9 "$process_id"
    fi

    kubectl port-forward -n $NAMESPACE $pod_name $port_mapping &
  done
}

if [ $# -eq 0 ]; then
  echo "Uso: $0 <app_name>"
  exit 1
fi

app_name="$1"
port_forward "$app_name"

