#!/usr/bin/env bash

echo "	--> start routing 50% of traffic to the v3 ratings system"
oc replace -f samples/bookinfo/kube/route-rule-reviews-50-v3.yaml

oc get routerule reviews-default -o yaml

echo "	--> wait until this version is proven in production (20 seconds should be enough :)"
sleep 20s;

echo "	--> start routing 50% of traffic to the v3 ratings system"
oc replace -f samples/bookinfo/kube/route-rule-reviews-v3.yaml