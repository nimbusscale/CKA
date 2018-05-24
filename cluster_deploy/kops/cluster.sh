#!/bin/bash
export NAME=lab.k8s.nimbusscale.com
export KOPS_STATE_STORE=s3://bct-jjk3-kops
export AWS_SDK_LOAD_CONFIG=1

kops create cluster \
    --node-count 2 \
    --zones "us-west-2a,us-west-2b" \
    --master-zones us-west-2a \
    --node-size t2.small \
    --master-size t2.medium \
    --topology public \
    --networking canal \
    --yes \
    --name ${NAME}