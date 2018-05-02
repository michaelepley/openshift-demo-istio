#!/usr/bin/env bash

echo "	--> generate some test load"
while true; do
    curl -o /dev/null -s -w "%{http_code}\n" http://istio-ingress-istio-system.2886795300-80-kitek02.environments.katacoda.com/productpage
  sleep .2
done

oc create -f samples/bookinfo/kube/mixer-rule-ratings-ratelimit.yaml

sleep 1s;

echo "	--> check the graphana dashbaord for 4xx errors and the success rate limited to 1 request / second"

oc get memquota handler -o yaml

sleep 1s;

oc delete -f samples/bookinfo/kube/mixer-rule-ratings-ratelimit.yaml

echo "Done."