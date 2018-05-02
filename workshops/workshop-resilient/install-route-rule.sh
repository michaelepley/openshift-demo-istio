IO_VERSION=0.6.0
export ISTIO_HOME=${HOME}/istio-${ISTIO_VERSION}
export PATH=${PATH}:${ISTIO_HOME}/bin
cd ${ISTIO_HOME}

echo "	--> Create a default route rule that directs all users to the v1 ratings components"
oc create -f samples/bookinfo/kube/route-rule-all-v1.yaml

echo "	--> Create a default route rule that directs (only) the user jason:jason to the v2 ratings system"
oc create -f samples/bookinfo/kube/route-rule-reviews-test-v2.yaml