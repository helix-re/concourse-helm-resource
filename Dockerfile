FROM google/cloud-sdk:251.0.0-alpine


ENV HELM_VERSION 2.14.1

ENV PATH /google-cloud-sdk/bin:$PATH

COPY assets /opt/resource
RUN chmod +x /opt/resource/*

RUN apk --no-cache add \
        curl \
        python \
        py-crcmod \
        bash \
        libc6-compat \
        openssh-client \
        git \
        openssl \
        tar \
        jq \
        ca-certificates \
        tzdata

RUN    gcloud --version \
       && gcloud components install kubectl

RUN curl -L -o helm.tar.gz \
        https://kubernetes-helm.storage.googleapis.com/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
        && tar -xvzf helm.tar.gz \
        && rm -rf helm.tar.gz \
        && chmod 0700 linux-amd64/helm \
        && mv linux-amd64/helm /usr/bin \
        && rm -rf linux-amd64 \
        && helm init --client-only \
        && helm plugin install https://github.com/viglesiasce/helm-gcs.git

ENTRYPOINT [ "/bin/bash" ]
