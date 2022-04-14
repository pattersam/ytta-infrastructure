FROM gitpod/workspace-full

# install aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install \
    && aws --version

# install kubectl
RUN curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin \
    && echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc \
    && kubectl version --short --client

# install helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    && ./get_helm.sh \
    && helm version

RUN helm plugin install https://github.com/databus23/helm-diff

# install hemlfile
RUN wget https://github.com/roboll/helmfile/releases/download/v0.143.1/helmfile_linux_amd64 -O helmfile_linux_amd64 \
    && chmod +x helmfile_linux_amd64 \
    && mv helmfile_linux_amd64 $HOME/bin/helmfile
