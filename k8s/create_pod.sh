#!/bin/bash
cat <<EOF | tee >( kubectl create -f - )
---
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: unity-test
  labels:
    app: unity-test
spec:
  template:
    metadata:
      labels:
        app: unity-test
        tier: web
    spec:
      containers:
      - name: unity-test
        image: gcr.io/$(echo ${GCLOUD_PROJECT})/unity-test:latest
        env:
        - name: IRON_TOKEN
          valueFrom:
            secretKeyRef:
              name: ironmq-creds
              key: token
        - name: IRON_PROJECT_ID
          valueFrom:
            secretKeyRef:
              name: ironmq-creds
              key: project
        ports:
        - containerPort: 8080
EOF