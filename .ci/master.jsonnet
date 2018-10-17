local project_name = std.extVar("project_name");
{
  "jobs": [
    {
      "name": "build_docker_image",
      "plan": [
        {
          "get": "build_number"
        },
        {
          "get": project_name+"-resource",
          "trigger": true
        },
        {
          "get_params": {
            "skip_download": true
          },
          "params": {
            "build": project_name+"-resource/",
            "cache": true,
            "cache_tag": "latest",
            "tag": "build_number/number",
            "tag_as_latest": true
          },
          "put": "docker"
        },
        {
          "params": {
            "bump": "patch"
          },
          "put": "build_number"
        }
      ]
    }
  ],
  "resource_types": null,
  "resources": [
    {
      "name": "build_number",
      "source": {
        "bucket": "helix-global-concourse-semvar",
        "driver": "gcs",
        "initial_version": "0.0.1",
        "json_key": "((helix-global-k8s-service-account))",
        "key": "concourse/"+project_name+"-resource"
      },
      "type": "semver"
    },
    {
      "name": project_name+"-resource",
      "source": {
        "branch": "master",
        "private_key": "((helix-ci-github-ssh-key))",
        "repo": "helix-re/"+project_name+"-resource",
        "uri": "git@github.com:helix-re/"+project_name+"-resource.git"
      },
      "type": "git"
    },
    {
      "name": "docker",
      "source": {
        "password": "((helix-global-k8s-service-account))",
        "repository": "us.gcr.io/helix-global/"+project_name+"-resource",
        "username": "_json_key"
      },
      "type": "docker-image"
    }
  ]
}
