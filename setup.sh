#!/bin/bash

set -e

PRIVATE_IP=10.128.6.3

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


    start_tomo='
    #!/bin/sh

# - IDENTITY (default to empty)
# - PASSWORD (default to empty)
# - PRIVATE_KEY (default to empty)
# - BOOTNODES (default to empty)
# - EXTIP (default to empty)
# - VERBOSITY (default to 3)
# - MAXPEERS (default to 25)  
# - SYNC_MODE (default to 'full')
# - NETWORK_ID (default to '89')
# - WS_SECRET (default to empty)
# - NETSTATS_HOST (default to 'netstats-server:3000')
# - NETSTATS_PORT (default to 'netstats-server:3000')

# constants
DATA_DIR="/data/tomo"
KEYSTORE_DIR="/data/tomo/keystore"

# variables
genesisPath=""
params=""
accountsCount=$(
  tomo account list --datadir $DATA_DIR  --keystore $KEYSTORE_DIR \
  2> /dev/null \
  | wc -l
)

# file to env
for env in IDENTITY PASSWORD PRIVATE_KEY BOOTNODES WS_SECRET NETSTATS_HOST \
           NETSTATS_PORT EXTIP SYNC_MODE NETWORK_ID ANNOUNCE_TXS STORE_REWARD DEBUG_MODE MAXPEERS; do
  file=$(eval echo "\$${env}_FILE")
  if [[ -f $file ]] && [[ ! -z $file ]]; then
    echo "Replacing $env by $file"
    export $env=$(cat $file)
  elif [[ "$env" == "BOOTNODES" ]] && [[ ! -z $file ]]; then
    echo "Bootnodes file is not available. Waiting for it to be provisioned..."
    while true ; do
      if [[ -f $file ]] && [[ $(grep -e enode $file) ]]; then
        echo "Fount bootnode file."
        break
      fi
      echo "Still no bootnodes file, sleeping..."
      sleep 5
    done
    export $env=$(cat $file)
  fi
done

# networkid
if [[ ! -z $NETWORK_ID ]]; then
  case $NETWORK_ID in
    88 )
      genesisPath="mainnet.json"
      ;;
    89 )
      genesisPath="testnet.json"
      params="$params --tomo-testnet --gcmode archive --rpcapi db,eth,net,web3,debug,posv"
      ;;
    90 )
      genesisPath="devnet.json"
      ;;
    * )
      echo "network id not supported"
      ;;
  esac
  params="$params --networkid $NETWORK_ID"
fi

# custom genesis path
if [[ ! -z $GENESIS_PATH ]]; then
  genesisPath="$GENESIS_PATH"
fi

# data dir
if [[ ! -d $DATA_DIR/tomo ]]; then
  echo "No blockchain data, creating genesis block."
  tomo init $genesisPath --datadir $DATA_DIR 2> /dev/null
fi

# identity
if [[ -z $IDENTITY ]]; then
  IDENTITY="unnamed_$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c6)"
fi

# password file
if [[ ! -f ./password ]]; then
  if [[ ! -z $PASSWORD ]]; then
    echo "Password env is set. Writing into file."
    echo "$PASSWORD" > ./password
  else
    echo "No password set (or empty), generating a new one"
    $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32} > password)
  fi
fi

# private key
if [[ $accountsCount -le 0 ]]; then
  echo "No accounts found"
  if [[ ! -z $PRIVATE_KEY ]]; then
    echo "Creating account from private key"
    echo "$PRIVATE_KEY" > ./private_key
    tomo  account import ./private_key \
      --datadir $DATA_DIR \
      --keystore $KEYSTORE_DIR \
      --password ./password
    rm ./private_key
  else
    echo "Creating new account"
    tomo account new \
      --datadir $DATA_DIR \
      --keystore $KEYSTORE_DIR \
      --password ./password
  fi
fi
account=$(
  tomo account list --datadir $DATA_DIR  --keystore $KEYSTORE_DIR \
  2> /dev/null \
  | head -n 1 \
  | cut -d"{" -f 2 | cut -d"}" -f 1
)
echo "Using account $account"
params="$params --unlock $account"

# bootnodes
if [[ ! -z $BOOTNODES ]]; then
  params="$params --bootnodes $BOOTNODES"
fi

# extip
if [[ ! -z $EXTIP ]]; then
  params="$params --nat extip:${EXTIP}"
fi

# syncmode
if [[ ! -z $SYNC_MODE ]]; then
  params="$params --syncmode ${SYNC_MODE}"
fi

# netstats
if [[ ! -z $WS_SECRET ]]; then
  echo "Will report to netstats server ${NETSTATS_HOST}:${NETSTATS_PORT}"
  params="$params --ethstats ${IDENTITY}:${WS_SECRET}@${NETSTATS_HOST}:${NETSTATS_PORT}"
else
  echo "WS_SECRET not set, will not report to netstats server."
fi

# annonce txs
if [[ ! -z $ANNOUNCE_TXS ]]; then
  params="$params --announce-txs"
fi

# store reward
if [[ ! -z $STORE_REWARD ]]; then
  params="$params --store-reward"
fi

# debug mode
if [[ ! -z $DEBUG_MODE ]]; then
  params="$params --gcmode archive --rpcapi db,eth,net,web3,debug,posv"
fi

# maxpeers
if [[ -z $MAXPEERS ]]; then
  MAXPEERS=25
fi

# dump
echo "dump: $IDENTITY $account $BOOTNODES"

set -x

exec tomo $params \
  --verbosity 3 \
  --metrics \
  --datadir $DATA_DIR \
  --keystore $KEYSTORE_DIR \
  --identity $IDENTITY \
  --maxpeers $MAXPEERS \
  --password /data/password \
  --port 30303 \
  --unlock $ACCOUNT_ADDRESS \
  --txpool.globalqueue 5000 \
  --txpool.globalslots 5000 \
  --rpc \
  --rpccorsdomain "*" \
  --rpcaddr 0.0.0.0 \
  --rpcport 8545 \
  --rpcvhosts "*" \
  --ws \
  --wsaddr 0.0.0.0 \
  --wsport 8546 \
  --wsorigins "*" \
  --mine \
  --gasprice "250000000" \
  --targetgaslimit "84000000" \
  "$@"'

    echo "$start_tomo" > /home/ubuntu/scripts/start.sh

    echo "[Unit]
Description=Tomo Node

[Service]
User=ubuntu
  
ExecStart=sh /home/ubuntu/scripts/start.sh \
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target"| sudo tee /etc/systemd/system/tomo.service

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
    rke_config='
# If you intended to deploy Kubernetes in an air-gapped environment,
# please consult the documentation on how to configure custom RKE images.
nodes:
- address: $PRIVATE_IP
port: "22"
internal_address: ""
role:
- controlplane
- worker
- etcd
hostname_override: ""
user: ubuntu
docker_socket: /var/run/docker.sock
ssh_key: ""
ssh_key_path: /home/ubuntu/.ssh/nirvana
ssh_cert: ""
ssh_cert_path: ""
labels: {}
taints: []
services:
etcd:
    image: ""
    extra_args: {}
    extra_args_array: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_args_array: {}
    win_extra_binds: []
    win_extra_env: []
    external_urls: []
    ca_cert: ""
    cert: ""
    key: ""
    path: ""
    uid: 0
    gid: 0
    snapshot: null
    retention: ""
    creation: ""
    backup_config: null
kube-api:
    image: ""
    extra_args: {}
    extra_args_array: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_args_array: {}
    win_extra_binds: []
    win_extra_env: []
    service_cluster_ip_range: 10.43.0.0/16
    service_node_port_range: ""
    pod_security_configuration: ""
    always_pull_images: false
    secrets_encryption_config: null
    audit_log: null
    admission_configuration: null
    event_rate_limit: null
kube-controller:
    image: ""
    extra_args: {}
    extra_args_array: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_args_array: {}
    win_extra_binds: []
    win_extra_env: []
    cluster_cidr: 10.42.0.0/16
    service_cluster_ip_range: 10.43.0.0/16
scheduler:
    image: ""
    extra_args: {}
    extra_args_array: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_args_array: {}
    win_extra_binds: []
    win_extra_env: []
kubelet:
    image: ""
    extra_args: {}
    extra_args_array: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_args_array: {}
    win_extra_binds: []
    win_extra_env: []
    cluster_domain: cluster.local
    infra_container_image: ""
    cluster_dns_server: 10.43.0.10
    fail_swap_on: false
    generate_serving_certificate: false
kubeproxy:
    image: ""
    extra_args: {}
    extra_args_array: {}
    extra_binds: []
    extra_env: []
    win_extra_args: {}
    win_extra_args_array: {}
    win_extra_binds: []
    win_extra_env: []
network:
plugin: canal
options: {}
mtu: 0
node_selector: {}
update_strategy: null
tolerations: []
authentication:
strategy: x509
sans: []
webhook: null
addons: ""
addons_include: []
system_images:
etcd: rancher/mirrored-coreos-etcd:v3.5.12
alpine: rancher/rke-tools:v0.1.100
nginx_proxy: rancher/rke-tools:v0.1.100
cert_downloader: rancher/rke-tools:v0.1.100
kubernetes_services_sidecar: rancher/rke-tools:v0.1.100
kubedns: rancher/mirrored-k8s-dns-kube-dns:1.23.0
dnsmasq: rancher/mirrored-k8s-dns-dnsmasq-nanny:1.23.0
kubedns_sidecar: rancher/mirrored-k8s-dns-sidecar:1.23.0
kubedns_autoscaler: rancher/mirrored-cluster-proportional-autoscaler:v1.8.9
coredns: rancher/mirrored-coredns-coredns:1.11.1
coredns_autoscaler: rancher/mirrored-cluster-proportional-autoscaler:v1.8.9
nodelocal: rancher/mirrored-k8s-dns-node-cache:1.23.0
kubernetes: rancher/hyperkube:v1.30.3-rancher1
flannel: rancher/mirrored-flannel-flannel:v0.25.1
flannel_cni: rancher/flannel-cni:v1.4.1-rancher1
calico_node: rancher/mirrored-calico-node:v3.28.0
calico_cni: rancher/calico-cni:v3.28.0-rancher1
calico_controllers: rancher/mirrored-calico-kube-controllers:v3.28.0
calico_ctl: rancher/mirrored-calico-ctl:v3.28.0
calico_flexvol: rancher/mirrored-calico-pod2daemon-flexvol:v3.28.0
canal_node: rancher/mirrored-calico-node:v3.28.0
canal_cni: rancher/calico-cni:v3.28.0-rancher1
canal_controllers: rancher/mirrored-calico-kube-controllers:v3.28.0
canal_flannel: rancher/mirrored-flannel-flannel:v0.25.1
canal_flexvol: rancher/mirrored-calico-pod2daemon-flexvol:v3.28.0
weave_node: ""
weave_cni: ""
pod_infra_container: rancher/mirrored-pause:3.7
ingress: rancher/nginx-ingress-controller:nginx-1.10.1-rancher1
ingress_backend: rancher/mirrored-nginx-ingress-controller-defaultbackend:1.5-rancher1
ingress_webhook: rancher/mirrored-ingress-nginx-kube-webhook-certgen:v1.4.1
metrics_server: rancher/mirrored-metrics-server:v0.7.1
windows_pod_infra_container: rancher/mirrored-pause:3.7
aci_cni_deploy_container: noiro/cnideploy:6.0.4.2.81c2369
aci_host_container: noiro/aci-containers-host:6.0.4.2.81c2369
aci_opflex_container: noiro/opflex:6.0.4.2.81c2369
aci_mcast_container: noiro/opflex:6.0.4.2.81c2369
aci_ovs_container: noiro/openvswitch:6.0.4.2.81c2369
aci_controller_container: noiro/aci-containers-controller:6.0.4.2.81c2369
aci_gbp_server_container: ""
aci_opflex_server_container: ""
ssh_key_path: /home/ubuntu/.ssh/nirvana
ssh_cert_path: ""
ssh_agent_auth: false
authorization:
mode: rbac
options: {}
ignore_docker_version: null
enable_cri_dockerd: null
kubernetes_version: ""
private_registries: []
ingress:
provider: ""
options: {}
node_selector: {}
extra_args: {}
dns_policy: ""
extra_envs: []
extra_volumes: []
extra_volume_mounts: []
update_strategy: null
http_port: 0
https_port: 0
network_mode: ""
tolerations: []
default_backend: null
default_http_backend_priority_class_name: ""
nginx_ingress_controller_priority_class_name: ""
default_ingress_class: null
cluster_name: ""
cloud_provider:
name: ""
prefix_path: ""
win_prefix_path: ""
addon_job_timeout: 0
bastion_host:
address: ""
port: ""
user: ""
ssh_key: ""
ssh_key_path: ""
ssh_cert: ""
ssh_cert_path: ""
ignore_proxy_env_vars: false
monitoring:
provider: ""
options: {}
node_selector: {}
update_strategy: null
replicas: null
tolerations: []
metrics_server_priority_class_name: ""
restore:
restore: false
snapshot_name: ""
rotate_encryption_key: false
dns: null'

    echo "$rke_config" > /home/ubuntu/cluster.yml
    cd /home/ubuntu
    rke up

    #install kubens
    curl -sS https://webi.sh/kubens | sh
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



create_prometheus_app(){
    mkdir /home/ubuntu/apps

    kubectl create namespace monitoring
    prometheus='
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prometheus
  namespace: monitoring
spec:
  project: default
  source:
    repoURL: https://github.com/jarvis-401/viction-mainnet.git
    path: charts/prometheus/
    targetRevision: HEAD
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: monitor
  syncPolicy:
    automated:
      prune: false          
      selfHeal: true         
    syncOptions:
      - CreateNamespace=true'

      echo "$prometheus" > /home/ubuntu/apps/prometheus.yml
      kubectl apply -f /home/ubuntu/apps/prometheus.yml -n monitoring
}

create_grafana_app(){
    grafana='
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: grafana
  namespace: monitoring
spec:
  project: default
  source:
    repoURL: https://github.com/jarvis-401/viction-mainnet.git
    path: charts/grafana/
    targetRevision: HEAD
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: monitor
  syncPolicy:
    automated:
      prune: false          
      selfHeal: true         
    syncOptions:
      - CreateNamespace=true'

      echo "$grafana" > /home/ubuntu/apps/grafana.yml
      kubectl apply -f /home/ubuntu/apps/grafana.yml -n monitoring
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
    create_prometheus_app &&
    create_grafana_app
    echo "Done"
}

main