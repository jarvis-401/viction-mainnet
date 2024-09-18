#!/bin/bash

set -e

# TODO: change these variables
PRIVATE_IP=""
SSH_KEY=""

install_docker(){
    sudo apt install docker.io
    sudo chmod 666 /var/run/docker.sock
}
setup_tomo(){
    wget https://github.com/BuildOnViction/victionchain/releases/download/v2.4.0/tomo-linux-amd64
    chmod a+x tomo-linux-amd64
    sudo mv tomo-linux-amd64 /usr/local/bin/tomo
    wget curl -L https://raw.githubusercontent.com/buildonViction/tomochain/master/genesis/mainnet.json -o /data/
    mkdir /home/ubuntu/scripts
    echo "1234" > /data/password

    source_bashrc='
export IDENTITY="viction-mainnet"
export SYNC_MODE="full" 
export NETWORK_ID="88"
export WS_SECRET="getty-site-pablo-auger-room-sos-blair-shin-whiz-delhi"
export NETSTATS_HOST="stats.viction.xyz"
export NETSTATS_PORT="443"
export GENESIS_PATH="/data/mainnet.json"
export KEYSTORE_DIR="/data/tomo/keystore"
export DATA_DIR="/data/tomo"
export KUBECONFIG=/home/ubuntu/kube_config_cluster.yml'

    sudo echo "$source_bash" > /home/ubuntu/.bashrc

    ACCOUNT_ADDRESS=$(tomo account new --password /data/password --keystore $KEYSTORE | grep 'Address:' | awk '{print $2}' | tr -d '{}')

    cp ./scipts/start.sh /home/ubuntu/scripts/start.sh
    cp ./scripts/tomo.service /etc/systemd/system/tomo.service

    sudo systemctl daemon-reload
    sudo systemctl enable tomo.service
    sudo systemctl start tomo.service
}


install_kubectl() {
    if command -v kubectl &> /dev/null
    then
        echo "kubectl is already installed. Skipping installation."
    else
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        echo "kubectl has been installed."
    fi
}

install_rke() {
    if command -v rke &> /dev/null
    then
        echo "RKE is already installed. Skipping installation."
    else
        echo "Installing RKE..."
        curl -LO https://github.com/rancher/rke/releases/download/v1.6.1/rke_linux-amd64
        chmod +x rke_linux-amd64
        sudo mv rke_linux-amd64 /usr/local/bin/rke
        echo "RKE has been installed."
    fi
}

setup_rke() {
    cp ./scripts/cluster.yml /home/ubuntu/cluster.yml
    cd /home/ubuntu
    rke up
}

install_helm(){
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

install_longhorn(){
    helm repo add longhorn https://charts.longhorn.io
    helm repo update
    kubectl create namespace longhorn-system
    helm install longhorn longhorn/longhorn --namespace longhorn-system
}

setup_argocd(){
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "argocd installed"
    sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64    
    sudo chmod +x /usr/local/bin/argocd
    sleep 30
    kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8000:443
    argocd login localhost:8000 --insecure --username admin --password $(kubectl get secrets argocd-initial-admin-secret -n argocd -o json | jq -r '.data.password' | base64 --decode)
    argocd repo add https://github.com/jarvis-401/viction-mainnet.git
}

create_apps(){
    kubectl create namespace monitoring
    kubectl apply -f ./apps/ -n monitoring
}

main() {
    install_docker &&
    setup_tomo &&
    install_kubectl &&
    install_rke &&
    setup_rke &&
    install_helm &&
    install_longhorn &&
    setup_argocd &&
    create_apps

    echo "Done"
}

main
