#!/usr/bin/env bash

oc create -f - <<EOF_CIRCUITBREAKER_STANDARD
  apiVersion: config.istio.io/v1alpha2
  kind: DestinationPolicy
  metadata:
    name: ratings-cb
  spec:
    destination:
      name: ratings
      labels:
        version: v1
    circuitBreaker:
      simpleCb:
        maxConnections: 1
        httpMaxPendingRequests: 1
        httpConsecutiveErrors: 1
        sleepWindow: 15m
        httpDetectionInterval: 10s
        httpMaxEjectionPercent: 100
EOF_CIRCUITBREAKER_STANDARD

sleep 1s;

echo "	--> overload the service to trigger the circuit breaker"
for i in {1..10} ; do
	curl 'http://istio-ingress-istio-system.2886795300-80-kitek02.environments.katacoda.com/productpage?foo=[1-1000]' >& /dev/null &
done

sleep 20s;

echo "	--> stop overloading"
for i in {1..10} ; do kill %${i} ; done

oc replace -f - <<EOF_CIRCUITBREAKER_PODEJECTION
  apiVersion: config.istio.io/v1alpha2
  kind: DestinationPolicy
  metadata:
    name: ratings-cb
  spec:
    destination:
      name: ratings
      labels:
        version: v1
    circuitBreaker:
      simpleCb:
        httpConsecutiveErrors: 1
        sleepWindow: 15m
        httpDetectionInterval: 10s
        httpMaxEjectionPercent: 100
EOF_CIRCUITBREAKER_PODEJECTION

sleep 1s;

echo "	--> to test pod injection, lets install a broken application component"

${ISTIO_HOME}/bin/istioctl kube-inject -f ~/broken.yaml | oc create -f -

oc get pods -l app=ratings

oc rollout status -w deployment/ratings-v1-broken

BROKEN_POD_NAME=$(oc get pods -l app=ratings,broken=true -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')

echo "	--> trigger the pod ejection by hitting the applicaiton"
curl http://istio-ingress-istio-system.2886795300-80-kitek02.environments.katacoda.com/productpage

echo "	--> notice a different ratings pod will replace the old one"
oc get pods -l app=ratings

echo "	--> it will have a nearly empty log, since it will be brand new after every ejection of the pod"
BROKEN_POD_NAME=$(oc get pods -l app=ratings,broken=true -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
oc logs -c ratings $BROKEN_POD_NAME

echo "	--> make sure to stop overloading before continuing"
for i in {1..10} ; do kill %${i}; done

echo "Done."
