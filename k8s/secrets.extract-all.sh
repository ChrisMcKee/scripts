#!/bin/bash

for ns in $(kubectl get namespace -o name | cut -d '/' -f 2); do
  # Set the namespaces to skip
  if [ "$ns" = "cattle-fleet-system" ] || [ "$ns" = "cattle-system" ] || [ "$ns" = "cattle-impersonation-system" ] || [ "$ns" = "kube-system" ] || [ "$ns" = "datadog" ] || [ "$ns" = "datadog-monitors" ] || [ "$ns" = "ingress-haproxy" ] || [ "$ns" = "default" ] || [ "$ns" = "fleet-system" ] || [ "$ns" = "kubernetes-ingress" ]; then
    echo "skipping $ns system"
  else
    for n in $(kubectl get --namespace $ns -o=name secrets); do
      nf=$(echo $n | cut -d '/' -f 2)
      # skip default tokens, service accounts and helm secrets etc
      if [[ "$nf" == *"-sa-"* ]]  || [[ "$nf" == "default"* ]] || [[ "$nf" == "azure-docker" ]] || [[ "$nf" == *"helm"* ]] || [[ "$nf" == *"cert-manager"* ]]; then
          echo "Skipping $nf"
          continue
      fi
      nf="${ns}-${nf}"
      kubectl get --namespace $ns -o=yaml $n > "$nf.yaml"
    done
  fi
done

echo "Processing complete."
