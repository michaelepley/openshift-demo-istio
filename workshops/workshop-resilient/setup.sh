#!/usr/bin/env bash

. ./config.sh

echo "	--> Installing istio"
. ./install-istio.sh

exit

echo "	--> Waiting for the ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} application to start....press any key to proceed"
while ! oc get pods | grep ${NAUTICALCHART_ORIGINAL_APPLICATION_NAME} | grep Running >/dev/null 2>&1 ; do echo -n "." && { read -t 1 -n 1 && break ; } && sleep 1s; done; echo ""


. ./install-sample-app.sh

echo "	--> Verify the review pods are running (2/2 should be running, one for the envoy sidecar container and one for the app container)"
oc get pods --selector app=reviews

. ./install-route-rule.sh

oc get routerules -o yaml
oc get routerules/reviews-default -o yaml
oc get routerule reviews-test-v2 -o yaml

echo "		--> examine the graphana dashboard to see traffic being routed to the v1 normally, and v2 for jason"

. ./install-fault-injection-test.sh

. ./clean-fault-injection-test.sh

. ./install-migrate-users.sh

. ./install-circuit-breaker.sh

echo "Done."
