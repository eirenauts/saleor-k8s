# Example installation

There are many approaches to deploying helm charts into a kubernetes cluster such as

- Plain [helm install](https://helm.sh/docs/helm/helm_install/)
- Gitops (eg [fluxcd](https://fluxcd.io/) or [argocd](https://argoproj.github.io/argo-cd/))
- Ansible [kubernetes modules](https://github.com/ansible-collections/community.kubernetes)

Any of the above approaches are perfectly valid. For the sake of simplicty, this article will describe an
approach using the [Ansible kubernetes modules](https://github.com/ansible-collections/community.kubernetes)

## Prerequisites

There are a number of required dependencies which must be installed before proceeding.

**_Required:_**

- [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-with-pip)
- [Helm client](https://helm.sh/docs/intro/install/)
- [Pip3](https://pypi.org/project/pip/)
- [venv](https://docs.python.org/3/library/venv.html#module-venv)
- [jq](https://stedolan.github.io/jq/download/)
- [jmespath](https://pypi.org/project/jmespath/)
- A running kubernetes cluster
- Jetstack certmanager installed and configured correctly on the kubernetes cluster
- DNS for the hostnames configured which will be used for the ingress objects
- A previously downloaded kubeconfig file and the path to the file
- A domain name
- A google recaptche linked to the domain and the google recaptcha private key
- A vatlayer key and vatlayer api key

**_Optional:_**

- An installed linkerd2 service mesh
- An openexchanges account and the api key
- A braintree account and braintree private key

The script below will install the required dependencies and activate a virtual environment from within which the
ansible playbooks can be run

```bash
sudo apt-get install python3-pip
source example/install_deps.sh
install_k8s_venv
install_helm_client
install_kubectl
activate_venv
```

## Populate the `vars/saleor_vars.json` file

The `vars/saleor_vars.json` file contains the variables which are expected for the deployment by
the ansible playbook. These are primarily secrets. Do not checkin this file into source control
with the real variables.

## Modify the `install-saleor.yaml` playbook

The `install-saleor.yaml` can be modified according to your requirements.
The settings for the various chart `values.yaml` files can be amended depending
on your requirements.

## Run the playbooks

```bash
source ../scripts/ci_functions.sh
activate_venv
ansible-playbook \
    -e @"vars/certmanager_vars.json" \
    ./playbooks/certmanager-certs.yaml &&
ansible-playbook \
    -e @"vars/saleor_vars.json" \
    ./playbooks/install-saleor.yaml
```
