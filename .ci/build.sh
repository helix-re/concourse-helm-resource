#!/bin/bash

docker build -t us.gcr.io/helix-global/concourse-helm-resource:$1 .

gcloud docker -- push us.gcr.io/helix-global/concourse-helm-resource:$1
