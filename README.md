# Helm Resource for Concourse

Deploy to a Kubernetes cluster via [Helm releases](https://github.com/kubernetes/helm) from [Concourse](https://concourse.ci/)

<hr>

🔌 This repository is a fork of <https://github.com/linkyard/concourse-helm-resource>

### Changes

- `kubeconfig` (a kubeconfig file) can be used for authenticating to Kubernetes
- `gcloud_auth`, `gcloud_project`, `gcloud_zone`, `gcloud_cluster` can be used to authenticate to Google Kubernetes Engine using a GCP service account key
- Native Helm `--wait` flag is used to determine the job's status (merged [PR #7](https://github.com/linkyard/concourse-helm-resource/pull/7))

## Installing

Add the resource type to your pipeline:
```
resource_types:
- name: helm
  type: docker-image
  source:
    repository: ilyasotkov/concourse-helm-resourse
    tag: 1.0.0
```


## Source Configuration

### Authentication

Authentication can be done either through a kubeconfig file or using GCP service account key:

* `kubeconfig`: *Required if `gcloud_auth` is not present.* kubeconfig file contents

* `gcloud_auth`: *Required if `kubeconfig` is not present.* GCP JSON private key file contents
* `gcloud_project`: *Required if `kubeconfig` is not present.* GCP project name
* `gcloud_zone`: *Required if `kubeconfig` is not present.* GCP default compute zone
* `gcloud_cluster`: *Required if `kubeconfig` is not present.* GKE cluster name

### Optional values

* `release`: *Optional.* Name of the release (not a file, a string). (Default: autogenerated by helm)
* `namespace`: *Optional.* Kubernetes namespace the chart will be installed into. (Default: default)
* `helm_init_server`: *Optional.* Installs helm into the cluster if not already installed. (Default: false)
* `tiller_namespace`: *Optional.* Kubernetes namespace where tiller is running (or will be installed to). (Default: kube-system)
* `tiller_service_account`: *Optional* Name of the service account that tiller will use (only applies if helm_init_server is true).
* `repos`: *Optional.* Array of Helm repositories to initialize, each repository is defined as an object with `name` and `url` properties.

## Behavior

### `check`: Check for new releases

Any new revisions to the release are returned, no matter their current state. The release must be specified in the
source for `check` to work.

### `in`: Not Supported

### `out`: Deploy the helm chart

Deploys a Helm chart onto the Kubernetes cluster. Tiller must be already installed
on the cluster.

#### Parameters

* `chart`: *Required.* Either the file containing the helm chart to deploy (ends with .tgz) or the name of the chart (e.g. `stable/mysql`).
* `release`: *Optional.* File containing the name of the release. (Default: taken from source configuration).
* `values`: *Optional.* File containing the values.yaml for the deployment. Supports setting multiple value files using an array.
* `override_values`: *Optional.* Array of values that can override those defined in values.yaml. Each entry in
  the array is a map containing a key and a value or path. Value is set directly while path reads the contents of
  the file in that path. A `hide: true` parameter ensures that the value is not logged and instead replaced with `***HIDDEN***`
* `version`: *Optional* Chart version to deploy. Only applies if `chart` is not a file.
* `delete`: *Optional.* Deletes the release instead of installing it. Requires the `name`. (Default: false)
* `purge`: *Optional.* Purge the release when delete is true. Requires the `name`. (Default: false)
* `replace`: *Optional.* Replace deleted release with same name. (Default: false)
* `devel`: *Optional.* Allow development versions of chart to be installed. This is useful when wanting to install pre-release
  charts (i.e. 1.0.2-rc1) without having to specify a version. (Default: false)
* `wait_until_ready`: *Optional.* Set to the number of seconds it should wait until all the resources in
    the chart are ready. (Default: `0` which means don't wait).
* `recreate_pods`: *Optional.* This flag will cause all pods to be recreated when upgrading. (Default: false)


## Example

Full example pipeline: <https://github.com/ilyasotkov/concourse-pipelines/blob/master/pipelines/gitlab-flow-semver.yml>

### Out

Define the resource:

```yaml
resources:
- name: myapp-helm
  type: helm
  source:
    kubeconfig: |
        apiVersion: v1
        kind: Config
        preferences: {}

        contexts:
        - context:
            cluster: development
            namespace: ramp
            user: developer
          name: dev-ramp-up
    repos:
      - name: some_repo
        url: https://somerepo.github.io/charts
```

```yaml
- name: helm-release
  type: helm
  source:
    gcloud_auth: |
        {
        "type": "service_account",
        "project_id": "XXX",
        "private_key_id": "XXX",
        "private_key": "XXX",
        "client_email": "XXX",
        "client_id": "XXX",
        "auth_uri": "XXX",
        "token_uri": "XXX",
        "auth_provider_x509_cert_url": "XXX",
        "client_x509_cert_url": "XXX"
        }
    gcloud_project: my-project-696969
    gcloud_zone: europe-west1-d
    gcloud_cluster: k8s-cluster
    repos:
    - name: my-charts
      url: https://my-charts.github.io/charts
```

Add to job:

```
jobs:
  # ...
  plan:
  - put: myapp-helm
    params:
      chart: source-repo/chart-0.0.1.tgz
      values: source-repo/values.yaml
      override_values:
      - key: replicas
        value: 2
      - key: version
        path: version/number # Read value from version/number
      - key: secret
        value: ((my-top-secret-value)) # Pulled from a credentials backend like Vault
        hide: true # Hides value in output
```
