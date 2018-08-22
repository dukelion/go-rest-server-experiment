#!/bin/bash
cat <<EOF | tee >( kubectl create -f - )
---
apiVersion: v1
kind: Secret
metadata:
  name: ironmq-creds
type: Opaque
data:
  token: $(echo -n ${IRON_TOKEN} | base64)
  project: $(echo -n ${IRON_PROJECT_ID} | base64)
EOF