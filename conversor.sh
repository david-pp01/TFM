#!/usr/bin/env bash
# extrae IP y puerto 6030 de r1–r4 y rellena plantilla

tpl="plantilla.txt"      # Archivo base con {{r1_IP}}, {{r1_PORT}}.
out="topologia.json"
cp "$tpl" "$out"         # Creamos salida.txt partiendo de plantilla original

for svc in r1 r2 r3 r4; do
  # Extraemos la IP externa y el nodePort 6030 usando jsonpath
  read ip port < <(
    kubectl get svc -n tfs "$svc" \
      -o=jsonpath='{.status.loadBalancer.ingress[0].ip} {.spec.ports[?(@.port==6030)].nodePort}'
  )
  if [[ -z "$ip" || -z "$port" ]]; then
    echo "Error $svc"
    continue
  fi

  # Reemplazamos en el fichero de salida los marcadores correspondientes
  sed -i \
    -e "s/{{${svc}_IP}}/${ip}/g" \
    -e "s/{{${svc}_PORT}}/${port}/g" \
    "$out"
  echo " $svc actualizado: IP=${ip}, PORT=${port}"
done

echo " Archivo generado: $out"

