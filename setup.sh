#!/usr/bin/env bash


# Configuration
. ./config-demo-openshift-istio.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
#None

echo -n "Verifying configuration ready..."
: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_USER_REFERENCE?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
echo "OK"

echo "Create Istio demo"

OPENSHIFT_PROJECT_DESCRIPTION_QUOTED=\'${OPENSHIFT_PROJECT_DESCRIPTION}\'

echo "	--> Make sure we can log in as an admin user; the istio demo will require an admin user"
pushd config >/dev/null 2>&1
	OPENSHIFT_USER_REFERENCE_ADMIN="OPENSHIFT_USER_RHTPSIO_ADMIN"
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE_ADMIN || { echo "FAILED: Could not login" && exit 1; }
	OPENSHIFT_USER_ADMIN_AUTH_TOKEN=`oc whoami -t`
popd >/dev/null 2>&1
echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE || { echo "FAILED: Could not login" && exit 1; }
	OPENSHIFT_USER_AUTH_TOKEN=`oc whoami -t`
popd >/dev/null 2>&1

[ "x${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS}" != "xfalse" ] || { echo "	--> Verify the openshift cluster is working normally" && oc status -v >/dev/null || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; } ; }

pushd workshops/workshop-resilient
. ./setup.sh
popd 

echo "Done."
