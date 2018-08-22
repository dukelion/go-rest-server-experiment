#!/bin/bash
external_ip=$(kubectl get svc unity-test-svc --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
while [ -z $external_ip ]; do
	echo "Waiting for ingress to come up.."
    sleep 10
    external_ip=$(kubectl get svc unity-test-svc --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
done

curl -s -o /dev/null -w "%{http_code}" -i -X POST \
   -H "Content-Type:application/json" \
   -d \
'{
"ts": "1530228282",
"sender": "testy-test-service",
  "message": {"foo":"bar"
},
"sent-from-ip": "1.2.3.4",
"priority": 2
}' \
 'http://'${external_ip}':8080/payload' && echo -e "\nService deployed"
