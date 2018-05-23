#!/bin/bash
export NAME=single.k8s.nimbusscale.com
export KOPS_STATE_STORE=s3://bct-jjk3-kops
export AWS_SDK_LOAD_CONFIG=1

kops create cluster \
    --node-count 1 \
    --zones us-west-2a \
    --master-zones us-west-2a \
    --node-size t2.small \
    --master-size t2.medium \
    --topology public \
    --networking canal \
    --yes
    --name ${NAME}