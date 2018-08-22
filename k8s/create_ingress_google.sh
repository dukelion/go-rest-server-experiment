#!/bin/bash
cat <<EOF | tee >( kubectl create -f - )
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "web-static-ip"
spec:
  backend:
    serviceName: unity-test-svc
    servicePort: 8080
EOF