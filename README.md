# Cluster management template project

Example [cluster management](https://docs.gitlab.com/ee/user/clusters/management_project.html) project.

This project is based on a GitLab [Project Template](https://docs.gitlab.com/ee/gitlab-basics/create-project.html).

For more information, see [the documentation for this template](https://docs.gitlab.com/ee/user/clusters/management_project_template.html).

Improvements can be proposed in the [original project](https://gitlab.com/gitlab-org/project-templates/cluster-management).

## Supported Kubernetes versions

The project should be used with a [supported version of Kubernetes cluster](https://docs.gitlab.com/ee/user/project/clusters/#supported-cluster-versions).

## Enabling Fluentd as syslog forwarder

Fluentd can be deployed as a central service to forward syslog messages to SIEM:

* Enable the Fluentd Helm chart:

    ```yaml
    helmfiles:
    - path: applications/fluentd/helmfile.yaml
    ```

* The above results in the `fluentd.gitlab-managed-apps` service, which accepts
  syslog messages on port 5140.

* To forward to the Elasticsearch service of the `elastic-stack` chart,
  uncomment the output in applications/fluentd/values.yaml:

    ```yaml
    04_outputs.conf: |-
      <label @OUTPUT>
        # Route all events to Elasticsearch.
        <match **>
          @type elasticsearch
          host "elastic-stack-elasticsearch-master.gitlab-managed-apps"
          port 9200
        </match>
      </label>
    ```

## Prerequisites

* [Install the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  ```bash
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  aws --version
  ```
* [Configure the AWS CLI with environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
  ```bash
  export AWS_ACCESS_KEY_ID=...
  export AWS_SECRET_ACCESS_KEY=...
  export AWS_DEFAULT_REGION=eu-central-1
  ```
* [Install `kubectl`](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)
  ```bash
  curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
  chmod +x ./kubectl
  mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
  echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
  kubectl version --short --client
  ```

## Setting up Amazon EKS

Following this [Getting started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html) guide.

### Step 1: Create the Amazon EKS cluster

* [x] Create an Amazon VPC
  ```bash
  aws cloudformation create-stack \
    --region eu-central-1 \
    --stack-name my-eks-vpc-stack \
    --template-body file://"aws-cloudformation/amazon-eks-vpc-private-subnets.yaml"
  ```
* [x] Create a cluster IAM role
  ```bash
  aws iam create-role \
    --role-name myAmazonEKSClusterRole \
    --assume-role-policy-document file://"aws-cloudformation/cluster-role-trust-policy.json"
  ```
* [x] Attach the required EKS IAM policy to the role
  ```bash
  aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
    --role-name myAmazonEKSClusterRole
  ```
* [x] Create the cluster (subnet list from https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1#subnets:)
  ```bash
  aws eks create-cluster --name my-cluster \
    --region eu-central-1 \
    --kubernetes-version 1.21 \
    --role-arn arn:aws:iam::407298002065:role/myAmazonEKSClusterRole \
    --resources-vpc-config subnetIds=subnet-0ef06ddc3ea08f4a0,subnet-0a94e6620791955ce,subnet-0e7c5b86f2f9ca0b6,subnet-0b4a496a0306a8f26
  ```

### Step 2: Configure your computer to communicate with your cluster

* [x] Configure `kubeconfig` file
  ```bash
  aws eks update-kubeconfig --region eu-central-1 --name my-cluster
  kubectl get svc
  ```

### Step 3: Create nodes (with Fargate)

* [x] Create a pod execution IAM
  ```bash
  aws iam create-role \
    --role-name myAmazonEKSFargatePodExecutionRole \
    --assume-role-policy-document file://"aws-cloudformation/pod-execution-role-trust-policy.json"
  ```
* [x] Attach the required Amazon EKS managed IAM policy to the role.
  ```bash
  aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy \
    --role-name myAmazonEKSFargatePodExecutionRole
  ```
* [x] Create Fargate profile for the app
  ```bash
  aws eks create-fargate-profile \
    --fargate-profile-name my-profile \
    --cluster-name my-cluster \
    --pod-execution-role-arn "arn:aws:iam::407298002065:role/myAmazonEKSFargatePodExecutionRole" \
    --subnets "subnet-0a94e6620791955ce" "subnet-0e7c5b86f2f9ca0b6" \
    --selectors namespace=eks-sample-app
  ```
* [x] Create Fargate profile for CoreDNS (only if all pods will be deployed to Fargate)
  ```bash
  aws eks create-fargate-profile \
    --fargate-profile-name CoreDNS \
    --cluster-name my-cluster \
    --pod-execution-role-arn "arn:aws:iam::407298002065:role/myAmazonEKSFargatePodExecutionRole" \
    --subnets "subnet-0a94e6620791955ce" "subnet-0e7c5b86f2f9ca0b6" \
    --selectors namespace=kube-system,labels={k8s-app=kube-dns}
  ```
* [x] Remove the `...compute-type : ec2` annotation from CoreDNS pods (to allow them to deploy to the new Fargate CoreDNS profile)
  ```bash
  kubectl patch deployment coredns \
    -n kube-system \
    --type json \
    -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
  ```
* [x] Restart CoreDNS
  ```bash
  kubectl rollout restart -n kube-system deployment coredns
  ```


## Installing the GitLab Agent

Following [this guide](https://docs.gitlab.com/ee/user/clusters/agent/install/index.html)

* [x] Created the `.gitlab/agents/my-agent/config.yaml` in this project
* [x] Added `my-agent` to this project from the Infrastructure > Kubernetes clusters page
* [x] Run the one-liner installation method
  ```bash
  docker run --pull=always --rm \
    registry.gitlab.com/gitlab-org/cluster-integration/gitlab-agent/cli:stable generate \
    --agent-token=... \
    --kas-address=wss://kas.gitlab.com \
    --agent-version stable \
    --namespace gitlab-kubernetes-agent | kubectl apply -f -
  ```
* [x] Create Fargate profile for the GitLab Agent
  ```bash
  aws eks create-fargate-profile \
    --fargate-profile-name gitlab-agent-profile \
    --cluster-name my-cluster \
    --pod-execution-role-arn "arn:aws:iam::407298002065:role/myAmazonEKSFargatePodExecutionRole" \
    --subnets "subnet-0a94e6620791955ce" "subnet-0e7c5b86f2f9ca0b6" \
    --selectors namespace=gitlab-kubernetes-agent
  ```
* [x] (Optional) Create Fargate profile for the GitLab Managed Apps
  ```bash
  aws eks create-fargate-profile \
    --fargate-profile-name gitlab-managed-apps-profile \
    --cluster-name my-cluster \
    --pod-execution-role-arn "arn:aws:iam::407298002065:role/myAmazonEKSFargatePodExecutionRole" \
    --subnets "subnet-0a94e6620791955ce" "subnet-0e7c5b86f2f9ca0b6" \
    --selectors namespace=gitlab-managed-apps
  ```
* [x] Added `KUBE_CONTEXT = youtube-tag-analyser/infrastructure-management:my-agent` environment variable to this project's CI/CD environment variables

## Create the deployment

* [x] Give the EKS cluster access to GitLab Container Registry (per [this guide](https://chris-vermeulen.com/using-gitlab-registry-with-kubernetes/))
  ```bash
  kubectl create secret docker-registry registry-credentials \
    --docker-server=https://registry.gitlab.com \
    --docker-username=REGISTRY_USERNAME \
    --docker-password=REGISTRY_PASSWORD \
    --docker-email=REGISTRY_EMAIL
  kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "registry-credentials"}]}'
  ```
* [x] Create Fargate profile for the main YTTA Application
  ```bash
  aws eks create-fargate-profile \
    --fargate-profile-name ytta-app-profile \
    --cluster-name my-cluster \
    --pod-execution-role-arn "arn:aws:iam::407298002065:role/myAmazonEKSFargatePodExecutionRole" \
    --subnets "subnet-0a94e6620791955ce" "subnet-0e7c5b86f2f9ca0b6" \
    --selectors namespace=ytta-app
  ```
* [x] Create namespace
  ```bash
  kubectl create namespace ytta-app
  ```
* [ ] Deploy with GitLab CI/CD, see [config](https://gitlab.com/youtube-tag-analyser/ytta-app/-/blob/main/.gitlab-ci.yml) for how this is done


## Other resources

* [Creating AWS Admin IAM user](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html)
