#!/usr/bin/env bash

[[ -v OPENSHIFT_USER_ADMIN_AUTH_TOKEN ]] || { echo "FAILED: you must have a user with clusteradmin privileges" && exit 1 ; }
# oc whoami -c | grep admin | grep  ${OPENSHIFT_MASTER//\./-} || { echo "FAILED: you must be logged in as a user with clusteradmin privileges" && exit 1 ; }

#curl -kL https://git.io/getLatestIstio | sed 's/curl/curl -k /g' | ISTIO_VERSION=${ISTIO_VERSION} sh -
#export PATH="$PATH:${ISTIO_HOME}/bin"
#cd ${ISTIO_HOME}

if [ "x${ISTIO_VERSION}" = "x" ] ; then
  ISTIO_VERSION=$(curl -k  -L -s https://api.github.com/repos/istio/istio/releases/latest | grep tag_name | sed "s/ *\"tag_name\": *\"\(.*\)\",*/\1/")
fi

NAME="istio-$ISTIO_VERSION"
URL="https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-${ISTIO_OSEXT}.tar.gz"
echo "Downloading $NAME from $URL ..."
curl -k  -L "$URL" | tar xz
# TODO: change this so the version is in the tgz/directory name (users trying multiple versions)
echo "Downloaded into $NAME:"
ls $NAME
BINDIR="$(cd $NAME/bin; pwd)"
echo "Add $BINDIR to your path; e.g copy paste in your shell and/or ~/.profile:"
echo "export PATH=\"\$PATH:$BINDIR\""


oc project istio-system || oc new-project istio-system --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not create the common istio system project" && exit 1 ; }

oc get nodes --show-labels --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} | grep 'region=infra' &&  oc annotate --overwrite  namespace/istio-system 'openshift.io/node-selector'='region=infra' && echo "WARNING: updated node selector for istio system to force installation on infrasturture nodes"
oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify anyuid permissions for istio-ingress-service-account" && exit 1 ; }
oc adm policy add-scc-to-user privileged -z istio-ingress-service-account --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify privileged permissions for istio-ingress-service-account" && exit 1 ; }
oc adm policy add-scc-to-user anyuid -z istio-egress-service-account --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify anyuid permissions for istio-egress-service-account" && exit 1 ; }
oc adm policy add-scc-to-user privileged -z istio-egress-service-account --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify privileged permissions for istio-egress-service-account" && exit 1 ; }
oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify anyuid permissions for istio-pilot-service-account" && exit 1 ; }
oc adm policy add-scc-to-user privileged -z istio-pilot-service-account --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify privileged permissions for istio-pilot-service-account" && exit 1 ; }
oc adm policy add-scc-to-user anyuid -z istio-grafana-service-account -n istio-system --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify permissions for istio-grafana-service-account" && exit 1 ; }
oc adm policy add-scc-to-user anyuid -z istio-prometheus-service-account -n istio-system --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify permissions for istio-grafana-service-account" && exit 1 ; }
oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify permissions for prometheus service account" && exit 1 ; }
oc adm policy add-scc-to-user privileged -z prometheus --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify permissions for prometheus service account" && exit 1 ; }
oc adm policy add-scc-to-user anyuid -z grafana -n istio-system --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify permissions for grafana service account" && exit 1 ; }
oc adm policy add-scc-to-user privileged -z grafana --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify permissions for grafana service account" && exit 1 ; }
oc adm policy add-scc-to-user anyuid -z default --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify permissions for default service account" && exit 1 ; }
oc adm policy add-scc-to-user privileged -z default --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify permissions for default service account" && exit 1 ; }
oc adm policy add-cluster-role-to-user cluster-admin -z default --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN} || { echo "FAILED: could not modify permissions for default service account" && exit 1 ; }

oc apply -f ${ISTIO_HOME}/install/kubernetes/istio.yaml --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN}
oc create -f ${ISTIO_HOME}/install/kubernetes/addons/prometheus.yaml --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN}
oc create -f ${ISTIO_HOME}/install/kubernetes/addons/grafana.yaml --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN}
oc create -f ${ISTIO_HOME}/install/kubernetes/addons/servicegraph.yaml --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN}
oc apply -f https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN}

oc expose svc grafana
oc expose svc servicegraph
oc expose svc jaeger-query
oc expose svc istio-ingress
oc expose svc prometheus


oc create role istio-user --verb=get,list,watch --resource=configmaps --token=${OPENSHIFT_USER_ADMIN_AUTH_TOKEN}

echo "Done."