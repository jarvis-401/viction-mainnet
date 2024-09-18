# Viction Mainnet

## Introduction

This repository contains a demo to set up a self-managed Kubernetes cluster with a Viction node and CI/CD pipeline, ensuring maintainability and observability.

---

### Architecture

![Viction-Node-Architecture](https://github.com/user-attachments/assets/5a8b1c18-b024-46ab-ab10-b592f8ed3e08)

---

### High-level Steps

1. **Set Up an RKE Cluster**: self-managed RKE cluster using a VM located in the USA
2. **Configure CI/CD Pipeline**: Utilize GitHub Actions and ArgoCD for CI/CD
3. **Deploy a Viction Node**: Install and configure a Viction node using binary
4. **Implement Monitoring and Telemetry**: Set up monitoring for the node using Prometheus and Grafana

---

### Directory Structure:
```bash
.
├── apps  // contains ArgoCD Apps
│   ├── grafana.yml
│   └── prometheus.yml
├── charts // Contains Helm Charts
│   ├── grafana // Grafana Helm Chart
│   │   ├── Chart.yaml
│   │   ├── dashboards
│   │   │   └── custom-dashboard.json
│   │   ├── README.md // Grafana Helm Chart Installation README
│   │   ├── templates // k8s Manifests to setup Grafana
│   │   │   ├── ....
│   │   └── values.yaml // base Values File
│   └── prometheus // Prometheus Helm Chart
│       ├── Chart.lock
│       ├── Chart.yaml
│       ├── templates  // k8s Manifests to setup Prometheus
│       │   ├── ...
│       └── values.yaml // base Values File
├── README.md
├── setup.sh // script to setup entire application stack / architecture
└── start.sh // entrypoint.sh script for Viction Mainnet 
```
---

## Setup

### Prerequisites
1. Linux Machine - (Prefer Ubuntu 18.04+)
2. Change Private IP in the variabel PRIVATE_IP in `setup.sh` in line number 5
3. Create a SSH Key and add name of the ssh key in the variable SSH_KEY in `setup.sh` in line number 6


### Option 01 - Using automated shell script - setup.sh

#### Clone the repository in your local machine and run it

```bash
$ git clone https://github.com/jarvis-401/viction-mainnet.git
$ cd viction-mainnet 
$ bash setup.sh
```

### Option 02: Deploy a viction-mainnet full node manually

#### Install TomoChain

Download and install the TomoChain binary and setup environment variables:
```bash
$ wget https://github.com/BuildOnViction/victionchain/releases/download/v2.4.0/tomo-linux-amd64
$ chmod a+x tomo-linux-amd64
$ sudo mv tomo-linux-amd64 /usr/local/bin/tomo

# Download the Genesis file
$ curl -L https://raw.githubusercontent.com/buildonViction/tomochain/master/genesis/mainnet.json -o /data/mainnet.json

# Set up directory structure
$ mkdir /home/ubuntu/scripts
$ echo "1234" > /data/password
```

#### Add the following environment variables to your ~/.bashrc:

```bash
$ export IDENTITY="viction-mainnet"
$ export SYNC_MODE="full" 
$ export NETWORK_ID="88"
$ export WS_SECRET="getty-site-pablo-auger-room-sos-blair-shin-whiz-delhi"
$ export NETSTATS_HOST="stats.viction.xyz"
$ export NETSTATS_PORT="443"
$ export GENESIS_PATH="/data/mainnet.json"
$ export KUBECONFIG=/home/ubuntu/kube_config_cluster.yml
```

#### Init genesis and create a new account or use an existing one by running:

```bash
$ tomo init tomo init $GENESIS_PATH --datadir /data/tomo

$ ACCOUNT_ADDRESS=$(tomo account new --password /data/password --keystore $KEYSTORE | grep 'Address:' | awk '{print $2}' | tr -d '{}')
```

#### Set up TomoChain as a service:

```bash
$ echo "[Unit]
Description=Tomo Node

[Service]
User=ubuntu
ExecStart=sh /home/ubuntu/scripts/start.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/tomo.service
```

#### Enable and start the service:

```bash
$ sudo systemctl daemon-reload
$ sudo systemctl enable tomo.service
$ sudo systemctl start tomo.service
```
---

### Test

1. **Check Logs**:

TODO: 
```bash
$ sudo journalctl -fu tomo.service
```

![Screenshot from 2024-09-17 18-14-44](https://github.com/user-attachments/assets/e383a42a-1e51-4ea0-aef9-932505fe3908)

2. **cURL**:

```bash
$curl --location '86.109.11.23:8545' \
--header 'Content-Type: application/json' \
--data '{
    "jsonrpc": "2.0",
    "method": "eth_syncing",
    "params": [],
    "id": 1
}'

```

---

### Monitoring

![Screenshot from 2024-09-17 19-36-43](https://github.com/user-attachments/assets/77c7e5f3-baa1-4209-b2e0-60e7d3652aa2)

The provided monitoring dashboard supports:
- The Current Dashboards Displays
1. CPU Utilization
2. Memory Utilization 
3. Disk Space Utilization
4. System Load 
5. Swap Used 

---

## Future Improvements
1. Support for Infrastructure as Code (IaC)
2. Add support to scrape and show blockchain node metrics - currently viction doesn't supprts it ([reference](https://github.com/BuildOnViction/victionchain/issues/432))
3. Add support for automated alerts based on metrics related to block time, mempool, transaction throughput, network lag, peer connectivity, etc.
4. Support for centralized logging using [Loki](https://grafana.com/oss/loki/)
5. Support for HA RPC node setup using HAProxy - to ensure traffic is only served from healthy nodes
6. Improve Security and Compliance by enforcing best practices like firewall rules, access policies, VPC configurations, etc.

---

## References

- [Grafana Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)
- [Prometheus Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)
- [Viction Node Setup](https://docs.viction.xyz/)