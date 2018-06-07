#!/bin/bash
set -e

die() { printf "${c_red}ERROR: %b" "$*\n"; exit 1; }
error_if_empty() { [ -n "${!1:-}" ] || die "Invalid payload (missing $1)"; }
info() { printf "${c_blue}%b${c_reset}" "$*\n"; }

setup_kubernetes() {
    payload=$1
    source=$2
    ls -la /root/
    mkdir -p /root/.kube
    gcloud_auth=$(jq -r '.source.gcloud_auth // ""' < $payload)
    kubeconfig=$(jq -r '.source.kubeconfig // ""' < $payload)

    if [ -n "$gcloud_auth" ]; then
        gcloud_project=$(jq -r '.source.gcloud_project // ""' < $payload)
        gcloud_cluster=$(jq -r '.source.gcloud_cluster // ""' < $payload)

        echo "$gcloud_auth" > gcloud-auth-key.json
        gcloud auth list
        gcloud auth activate-service-account --key-file gcloud-auth-key.json
        gcloud auth list
        gcloud container clusters get-credentials $gcloud_cluster --zone us-west1-a --project $gcloud_project
    elif [ -n "$kubeconfig" ]; then
        echo "$kubeconfig" > /root/.kube/config
    else
        echo "Must specify either \"gcloud_auth\" or \"kubeconfig\" for authenticating to Kubernetes."
    fi

    kubectl cluster-info
    kubectl version
}

setup_helm() {
    init_server=$(jq -r '.source.helm_init_server // "false"' < $1)
    tiller_namespace=$(jq -r '.source.tiller_namespace // "kube-system"' < $1)

    if [ "$init_server" = true ]; then
        tiller_service_account=$(jq -r '.source.tiller_service_account // "default"' < $1)
        helm init --tiller-namespace=$tiller_namespace --service-account=$tiller_service_account --upgrade
        wait_for_service_up tiller-deploy 10
    else
        helm init -c --tiller-namespace $tiller_namespace > /dev/nulll
    fi

    helm version --tiller-namespace $tiller_namespace
}

wait_for_service_up() {
    SERVICE=$1
    TIMEOUT=$2
    if [ "$TIMEOUT" -le "0" ]; then
        echo "Service $SERVICE was not ready in time"
        exit 1
    fi
    RESULT=`kubectl get endpoints --namespace=$tiller_namespace $SERVICE -o jsonpath={.subsets[].addresses[].targetRef.name} 2> /dev/null || true`
    if [ -z "$RESULT" ]; then
        sleep 1
        wait_for_service_up $SERVICE $((--TIMEOUT))
    fi
}

setup_resource() {
    echo "Initializing kubectl..."
    setup_kubernetes $1 $2
    echo "Initializing helm..."
    setup_helm $1
}
