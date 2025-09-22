#!/usr/bin/env bash
# extrae IP de interfaz vnxtun* y nodePort 6030 de r1–r4 y rellena plantilla

tpl="plantilla.txt"    # Archivo base con {{r1_IP}}, {{r1_PORT}}, etc.
out="topologia.json"
cp "$tpl" "$out"       # Clonamos la plantilla

# Extraer IP de la primera interfaz que coincida con 'vnxtun'
vnx_iface=$(ifconfig | grep -oE '^vnxtun[^:]*' | head -n1)
if [[ -z "$vnx_iface" ]]; then
  echo " No se encontró interfaz tipo 'vnxtun'"
  exit 1
fi

# Obtener la IP asociada a esa interfaz
ip=$(ifconfig "$vnx_iface" | awk '/inet / {print $2}')
if [[ -z "$ip" ]]; then
  echo "No se pudo obtener IP de $vnx_iface"
  exit 1
fi
echo "$vnx_iface: $ip"


for svc in r1 r2 r3 r4; do
  # Obtener nodePort para puerto 6030
  port=$(microk8s kubectl get svc -n tfs "$svc" \
    -o=jsonpath='{.spec.ports[?(@.port==6030)].nodePort}')
  
  if [[ -z "$port" ]]; then
    echo " Omitido $svc: no se encontró port 6030"
    continue
  fi

  # Reemplazar IP (misma para todos) y port
  sed -i \
    -e "s/{{${svc}_IP}}/${ip}/g" \
    -e "s/{{${svc}_PORT}}/${port}/g" \
    "$out"
  
  echo " $svc actualizado: IP=$ip, PORT=$port"
done

echo "Archivo generado: $out"

