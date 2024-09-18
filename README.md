### Task Description
1. The objective is to set up and demonstrate a sustainable, self-managed Kubernetes cluster with a Viction node and CI/CD pipeline, ensuring long-term maintainability and observability. The following steps outline the key tasks involved:
- Set Up an RKE Cluster:<br />
- Deploy a self-managed Rancher Kubernetes Engine (RKE) cluster using a virtual machine (VM) located in the USA.<br />

2. Configure CI/CD Pipeline:<br />

- Utilize GitHub Actions and ArgoCD to set up a continuous integration/continuous deployment (CI/CD) pipeline for automated code updates and deployments.<br />

3. Deploy a Viction Node:<br />


- Install and configure a Viction node using its binary (without Docker).<br />

- Ensure that the deployment is sustainable and maintainable over time, focusing on ease of updates and scalability.<br />

4. Implement Monitoring and Telemetry:<br />

- Set up monitoring and telemetry for the node using Prometheus and Grafana.<br />

- Configure the system to track key metrics and logs for real-time observability.<br />

5. Provide Evidence of Node Syncing:<br />

- Once the Viction node begins syncing, capture a screenshot of the logs and metrics. <br />

6. Repository Sharing: <br />

- Share the GitHub repository with:
- vinpate
- Oxdevin
- jmcglock<br />
7. Live Demo: <br />

- Prepare for a live demo of your entire setup during the next interview, where you will showcase the RKE cluster, Viction node, and monitoring infrastructure.

---

### Repo Structure:
```bash
.
├── apps  ( Contains ArgoCD Apps )
│   ├── grafana.yml
│   └── prometheus.yml
├── charts (Contains Helm Charts )
│   ├── grafana ( Grafana's Helm Chart )
│   │   ├── Chart.yaml
│   │   ├── dashboards
│   │   │   └── custom-dashboard.json
│   │   ├── README.md ( Grafana Helm Chart Installation Readme )
│   │   ├── templates ( It Contains K8s Manifests Files For Grafana Setup )
│   │   │   ├── clusterrolebinding.yaml
│   │   │   ├── clusterrole.yaml
│   │   │   ├── configmap-dashboard-provider.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── configSecret.yaml
│   │   │   ├── _config.tpl
│   │   │   ├── dashboards-json-configmap.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── extra-manifests.yaml
│   │   │   ├── headless-service.yaml
│   │   │   ├── _helpers.tpl
│   │   │   ├── hpa.yaml
│   │   │   ├── image-renderer-deployment.yaml
│   │   │   ├── image-renderer-hpa.yaml
│   │   │   ├── image-renderer-network-policy.yaml
│   │   │   ├── image-renderer-servicemonitor.yaml
│   │   │   ├── image-renderer-service.yaml
│   │   │   ├── ingress.yaml
│   │   │   ├── networkpolicy.yaml
│   │   │   ├── NOTES.txt
│   │   │   ├── poddisruptionbudget.yaml
│   │   │   ├── podsecuritypolicy.yaml
│   │   │   ├── _pod.tpl
│   │   │   ├── pvc.yaml
│   │   │   ├── rolebinding.yaml
│   │   │   ├── role.yaml
│   │   │   ├── secret-env.yaml
│   │   │   ├── secret.yaml
│   │   │   ├── serviceaccount.yaml
│   │   │   ├── servicemonitor.yaml
│   │   │   ├── service.yaml
│   │   │   ├── statefulset.yaml
│   │   │   └── tests
│   │   │       ├── test-configmap.yaml
│   │   │       ├── test-podsecuritypolicy.yaml
│   │   │       ├── test-rolebinding.yaml
│   │   │       ├── test-role.yaml
│   │   │       ├── test-serviceaccount.yaml
│   │   │       └── test.yaml
│   │   └── values.yaml (Base Values File )
│   └── prometheus ( Prometheus Helm Chart )
│       ├── Chart.lock
│       ├── Chart.yaml
│       ├── templates  ( It Contains K8s Manifests Files For Prometheus Setup )
│       │   ├── clusterrolebinding.yaml
│       │   ├── clusterrole.yaml
│       │   ├── cm.yaml
│       │   ├── deploy.yaml
│       │   ├── extra-manifests.yaml
│       │   ├── headless-svc.yaml
│       │   ├── _helpers.tpl
│       │   ├── ingress.yaml
│       │   ├── network-policy.yaml
│       │   ├── NOTES.txt
│       │   ├── pdb.yaml
│       │   ├── psp.yaml
│       │   ├── pvc.yaml
│       │   ├── rolebinding.yaml
│       │   ├── serviceaccount.yaml
│       │   ├── service.yaml
│       │   ├── sts.yaml
│       │   └── vpa.yaml
│       ├── values.schema.json
│       └── values.yaml ( Base Values File )
├── README.md
├── setup.sh ( Whole Architecture Setup Shell Script )
└── start.sh ( Shell Script For Viction Mainnet Entrypoint.sh )
```

---
### Viction Mainnet Node Setup Using RKE <br />
<br />

1. Setup Viction mainnet node on Cloud VM with Binaries 
2. Setup Deploy a RKE k8s cluster on that VM
3. Setup monitoring for viction testnet node using prometheus and grafana
   <br />
---

### Architecture

![Viction-Node-Architecture](https://github.com/user-attachments/assets/5a8b1c18-b024-46ab-ab10-b592f8ed3e08)

# Viction Mainnet Node Setup

This document provides instructions to set up a Viction Mainnet Node using Docker, TomoChain, Node Exporter, and RKE. Follow the steps below to configure and run the node.

---

### Viction Node Logs

![Screenshot from 2024-09-17 18-14-44](https://github.com/user-attachments/assets/e383a42a-1e51-4ea0-aef9-932505fe3908)

---

### Dashboard

![Screenshot from 2024-09-17 19-36-43](https://github.com/user-attachments/assets/77c7e5f3-baa1-4209-b2e0-60e7d3652aa2)

---

## Steps

### 0. Setup a SSH Key which will be used further 
---

### 1. Install Docker

Make sure Docker is installed on your machine. If it is not installed, you can use the following command:

```bash
sudo apt install docker.io
sudo chmod 666 /var/run/docker.sock
```
---

### 2.Install TomoChain

Download and install the TomoChain binary and setup environment variables:

```bash
wget https://github.com/BuildOnViction/victionchain/releases/download/v2.4.0/tomo-linux-amd64
chmod a+x tomo-linux-amd64
sudo mv tomo-linux-amd64 /usr/local/bin/tomo

# Download the Genesis file
curl -L https://raw.githubusercontent.com/buildonViction/tomochain/master/genesis/mainnet.json -o /data/mainnet.json

# Set up directory structure
mkdir /home/ubuntu/scripts
echo "1234" > /data/password
```


### 3. Add the following environment variables to your ~/.bashrc:

```bash
export IDENTITY="viction-mainnet"
export SYNC_MODE="full" 
export NETWORK_ID="88"
export WS_SECRET="getty-site-pablo-auger-room-sos-blair-shin-whiz-delhi"
export NETSTATS_HOST="stats.viction.xyz"
export NETSTATS_PORT="443"
export GENESIS_PATH="/data/mainnet.json"
export KEYSTORE="/data/tomo/keystore"
export KUBECONFIG=/home/ubuntu/kube_config_cluster.yml
```


### 4. Create a new account or use an existing one by running:

```bash
ACCOUNT_ADDRESS=$(tomo account new --password /data/password --keystore $KEYSTORE | grep 'Address:' | awk '{print $2}' | tr -d '{}')
```

### 5. Set up TomoChain as a service:

```bash
echo "[Unit]
Description=Tomo Node

[Service]
User=ubuntu
ExecStart=sh /home/ubuntu/scripts/start.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/tomo.service
```

### 6. Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable tomo.service
sudo systemctl start tomo.service
```

<br />
---

### Reference

Grafana Helm Chart - https://github.com/grafana/helm-charts/tree/main/charts/grafana

Prometheus Helm Chart - https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus

Viction Node Setup Doc - https://docs.viction.xyz/

---
### Note: There is an open issue regarding metrics

They have not added metrics in there code
Although i have added the flag for metrics in the chain config

**issue**
Link - https://github.com/BuildOnViction/victionchain/issues/432
---
---
### Future Imrpovements

1. **Infrastructure as Code (IaC) with Terraform**
Why: To ensure infrastructure consistency and enable scalability, using Terraform or Terragrunt (which you prefer) can automate the provisioning and management of the infrastructure.
How: Implement Terraform scripts to manage your entire cloud infrastructure, including Kubernetes clusters, VMs, storage, networking, and more.
Use Terraform modules for reusable infrastructure components.
Integrate with Terraform state management for easy collaboration and rollbacks.
Use Terraform providers for cloud services such as AWS, GCP, or Azure to automatically provision VMs, databases, and load balancers required for blockchain nodes.
Outcome: Easier scaling, version-controlled infrastructure, and quicker disaster recovery. <br />
2. **Enhance Monitoring with More Granular Metrics **
Why: Expanding the range of metrics will give you deeper insights into system performance and help catch issues before they affect the system.
How:
Add monitoring for more specific network-related metrics, such as packet loss, latency, and bandwidth usage.
Track the performance of blockchain nodes by including specific metrics related to block time, transaction throughput, and peer connectivity.
Use Grafana annotations to correlate infrastructure changes (like deployments) with performance spikes or downtimes.
Set up anomaly detection using Prometheus/Grafana to detect unusual patterns and receive alerts for potential issues even if thresholds aren't explicitly breached. <br />
3. **Centralized Logging**
Why: Centralized logging can simplify debugging and performance monitoring across multiple nodes and services.
How:
Use ELK stack (Elasticsearch, Logstash, Kibana) or Grafana Loki to centralize logs from your blockchain nodes, Kubernetes pods, and other services.
Integrate log analysis with Grafana dashboards to correlate logs with performance metrics and alerts.
Set up alerts based on specific log patterns (e.g., high error rates). <br />
4. **Automated Backups & Disaster Recovery**
Why: To prevent data loss and ensure quick recovery from failures, automated backups are essential.
How:
Use Terraform to provision S3 buckets (or equivalent storage) for storing backups of your blockchain nodes and other critical data.
Schedule automatic backups of your blockchain state and infrastructure configuration.
Set up a disaster recovery strategy by automating the restoration of the environment in a different region or cloud provider using Terraform. <br />
5. **Improve Security and Compliance**
Why: As the infrastructure scales, security becomes increasingly important to protect sensitive data and ensure compliance.
How:
Use Terraform to define and enforce security best practices (e.g., firewall rules, IAM policies, VPC configurations) across cloud infrastructure.
Integrate HashiCorp Vault for secret management, ensuring that private keys, credentials, and other sensitive information are stored securely.
Automate TLS/SSL certificate management for blockchain node communication.
Implement role-based access control (RBAC) for Prometheus, Grafana, and other monitoring tools to ensure only authorized users can make critical changes. <br />
6. **Load Balancing and High Availability (HA)**
Why: To ensure uptime and resilience in case of a node failure, HA can improve the reliability of the system.
How:
Use Terraform to provision load balancers (e.g., AWS ALB/ELB, Google Cloud Load Balancer) to distribute traffic between multiple blockchain nodes.
Implement HAProxy or Nginx as a reverse proxy for your nodes to manage traffic distribution across the network.
Use Terraform to manage auto-scaling groups and ensure that additional nodes are automatically spun up if resource usage exceeds predefined limits.


This `README.md` explains the setup process for the architecture and includes all necessary commands and explanations for running the services.
