# Microservices Deployment on Azure Kubernetes Service (AKS)

Infrastructure-as-Code project that provisions an AKS cluster on Azure using Terraform, deploys a Node.js REST API backed by PostgreSQL Flexible Server, and manages workloads with Helm.

---

## Architecture Overview

```
                        ┌──────────────────────────────────────────────────────┐
                        │              Azure Resource Group                    │
                        │              (helm-resource-group)                   │
                        │                                                      │
                        │  ┌──────────────────────────────────────────────┐    │
                        │  │        Virtual Network (10.0.0.0/16)         │    │
                        │  │        helmaks-vnet                          │    │
                        │  │                                              │    │
                        │  │  ┌──────────────┐  ┌──────────────┐         │    │
                        │  │  │ web subnet   │  │ app subnet   │         │    │
                        │  │  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │         │    │
                        │  │  │ (ACR PE)     │  │              │         │    │
                        │  │  └──────────────┘  └──────────────┘         │    │
                        │  │                                              │    │
                        │  │  ┌──────────────┐  ┌────────────────────┐   │    │
                        │  │  │ database     │  │ aks subnet         │   │    │
                        │  │  │ subnet       │  │ 10.0.4.0/24        │   │    │
                        │  │  │ 10.0.3.0/24  │  │                    │   │    │
                        │  │  │ (PG deleg.)  │  │ ┌────────────────┐ │   │    │
                        │  │  └──────┬───────┘  │ │ AKS Cluster    │ │   │    │
                        │  │         │          │ │ 3 Nodes        │ │   │    │
                        │  │         ▼          │ │ Standard_a2_v2 │ │   │    │
                        │  │  ┌──────────────┐  │ │                │ │   │    │
                        │  │  │ PostgreSQL   │  │ │ ┌─────────┐   │ │   │    │
                        │  │  │ Flex Server  │  │ │ │ Node.js │   │ │   │    │
                        │  │  │ (B_Std_B1ms) │  │ │ │ API     │   │ │   │    │
                        │  │  │ myappdb      │◄─┤ │ │ :3000   │   │ │   │    │
                        │  │  └──────────────┘  │ │ └─────────┘   │ │   │    │
                        │  │                    │ └────────────────┘ │   │    │
                        │  │                    └────────────────────┘   │    │
                        │  └────────────────────────────────────────────┘    │
                        │                                                      │
                        │  ┌──────────────┐  ┌────────────────────────────┐   │
                        │  │ ACR          │◄─┤ Private Endpoint           │   │
                        │  │ helmaksacr   │  │ + DNS: privatelink.        │   │
                        │  │ (Premium)    │  │   azurecr.io               │   │
                        │  └──────────────┘  └────────────────────────────┘   │
                        │                                                      │
                        │  ┌─────────────────────────────────────────────┐    │
                        │  │ Private DNS Zone                            │    │
                        │  │ privatelink.postgres.database.azure.com     │    │
                        │  │ (linked to VNet for PostgreSQL resolution)  │    │
                        │  └─────────────────────────────────────────────┘    │
                        └──────────────────────────────────────────────────────┘
```

**Key components:**

| Component | Purpose |
|---|---|
| **AKS Cluster** | Hosts the Node.js API as containerised workloads (3 nodes, Standard tier) |
| **Azure Container Registry (ACR)** | Stores and serves the `nodeapp` container image (Premium SKU) |
| **PostgreSQL Flexible Server** | Managed database (`myappdb`) with VNet integration and private DNS |
| **Virtual Network** | Network isolation with dedicated subnets for web, app, database, and AKS |
| **Private Endpoints & DNS** | Secures ACR and PostgreSQL access over private links (no public internet) |
| **Helm Chart** | Packages the Kubernetes deployment, service, secrets injection, and probes |
| **Kubernetes Secret** | Stores database credentials (`basic-auth`) injected into pods as env vars |

---

## Project Structure

```
.
├── App/                            # Node.js application source
│   ├── server.js                   #   Express REST API with PostgreSQL (pg) connection
│   ├── package.json                #   Dependencies: express ^4.21.0, pg ^8.13.0
│   ├── Dockerfile                  #   Multi-stage build (node:20-alpine, port 3000)
│   └── .dockerignore               #   Docker build exclusions
│
├── backend/                        # Terraform remote state infrastructure
│   ├── main.tf                     #   Storage account + container for tfstate
│   └── providers.tf                #   AzureRM provider config
│
├── env/                            # Per-environment root modules
│   ├── dev/                        #   Development (fully configured)
│   │   ├── main.tf                 #     Resource group, modules, Helm release, kubeconfig provisioner
│   │   ├── variables.tf            #     Input variable declarations
│   │   ├── terraform.tfvars        #     Variable values for dev
│   │   ├── providers.tf            #     AzureRM, Kubernetes, Helm provider config
│   │   ├── backend.tf              #     Remote state backend config (Azure Storage)
│   │   └── outputs.tf              #     Output values
│   ├── stage/                      #   Staging (template — not yet configured)
│   └── prod/                       #   Production (template — not yet configured)
│
├── modules/                        # Reusable Terraform modules
│   ├── aks/                        #   AKS cluster + AcrPull role + K8s namespace + secret
│   ├── compute/                    #   Azure Container Registry (Premium SKU)
│   ├── database/                   #   PostgreSQL Flexible Server + database
│   ├── networking/                 #   VNet + subnets (web, app, database, aks)
│   ├── private_endpoint/           #   Private endpoints + DNS zones for ACR and PostgreSQL
│   └── security/                   #   Security (template — not yet implemented)
│
├── myapp/                          # Helm chart
│   ├── Chart.yaml                  #   Chart metadata (v0.1.0)
│   ├── values.yaml                 #   Default values (image, replicas, probes, service type)
│   └── templates/                  #   Kubernetes manifests
│       ├── deployment.yaml         #     Deployment with env vars from secret, liveness/readiness probes
│       ├── service.yaml            #     Service (LoadBalancer, port 3000)
│       ├── serviceaccount.yaml     #     ServiceAccount
│       ├── ingress.yaml            #     Ingress (disabled by default)
│       ├── httproute.yaml          #     Gateway API HTTPRoute (disabled by default)
│       ├── hpa.yaml                #     HorizontalPodAutoscaler (disabled by default)
│       ├── _helpers.tpl            #     Template helpers (naming, labels)
│       ├── NOTES.txt               #     Post-install instructions
│       └── tests/
│           └── test-connection.yaml
│
└── workspace/                      # VS Code multi-root workspace files
```

---

## Prerequisites

| Tool | Minimum Version | Purpose |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.0 | Infrastructure provisioning |
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | >= 2.50 | Azure authentication and cluster credentials |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | >= 1.28 | Kubernetes cluster management |
| [Helm](https://helm.sh/docs/intro/install/) | >= 3.0 | Kubernetes package management |
| [Docker](https://docs.docker.com/get-docker/) | >= 20.10 | Building and pushing container images |
| [Node.js](https://nodejs.org/) | >= 20 | Local development (optional) |

An active Azure subscription is required. Authenticate before running any commands:

```bash
az login
```

---

## Terraform Providers

| Provider | Version | Registry |
|---|---|---|
| azurerm | 4.65.0 | hashicorp/azurerm |
| kubernetes | 3.0.1 | hashicorp/kubernetes |
| helm | 3.1.1 | hashicorp/helm |

---

## Getting Started

### 1. Provision the Remote State Backend

The backend stores Terraform state in an Azure Storage Account with versioning and TLS 1.2 enforcement.

```bash
cd backend
terraform init
terraform apply
```

### 2. Deploy the Dev Environment

```bash
cd env/dev
terraform init
terraform plan
terraform apply
```

This provisions the following in a single apply:
- Resource group (`helm-resource-group` in East US)
- Virtual network with four subnets
- Azure Container Registry (`helmaksacr`, Premium) with a private endpoint
- AKS cluster (`helm-aks-cluster`, 3 nodes, Standard tier) with `AcrPull` role assignment
- PostgreSQL Flexible Server (`helmaks-postgresql`, v12, B_Standard_B1ms) with VNet integration
- PostgreSQL database (`myappdb`)
- Private DNS zones for ACR and PostgreSQL
- Kubernetes namespace (`myapp`), secret (`basic-auth`) with DB credentials
- Helm release of the `myapp` chart into the `myapp` namespace
- Automatic kubeconfig refresh via `null_resource` provisioner

### 3. Build and Push the Container Image

> **Important:** If building on Apple Silicon (M1/M2/M3), you must target `linux/amd64` since AKS nodes run AMD64.

```bash
cd App

# Login to ACR
az acr login --name helmaksacr

# Build for the correct platform
docker build --platform linux/amd64 -t helmaksacr.azurecr.io/nodeapp:v1 .

# Push to ACR
docker push helmaksacr.azurecr.io/nodeapp:v1
```

### 4. Verify the Deployment

After `terraform apply` completes, the kubeconfig is updated automatically. Verify:

```bash
kubectl get nodes
kubectl get pods -n myapp
kubectl get svc -n myapp
```

The service is exposed as a `LoadBalancer` on port 3000. It may take a few minutes for the external IP to be assigned.

```bash
# Test the API
curl http://<EXTERNAL-IP>:3000/health
curl http://<EXTERNAL-IP>:3000/items
```

---

## Node.js Application

The `App/` directory contains a REST API built with Express and the `pg` library, designed to connect to Azure PostgreSQL Flexible Server.

### API Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check — returns `{"status": "healthy"}` |
| `GET` | `/items` | List all items |
| `POST` | `/items` | Create an item (body: `{"name": "..."}`) |
| `GET` | `/items/:id` | Get a single item by ID |
| `DELETE` | `/items/:id` | Delete an item by ID |

### Environment Variables

The app reads these from the Kubernetes secret `basic-auth` (injected via the deployment template):

| Variable | Source Secret Key | Description |
|---|---|---|
| `DB_HOST` | `host` | PostgreSQL server hostname |
| `DB_NAME` | `name` | Database name (`myappdb`) |
| `DB_USER` | `username` | Database admin username |
| `DB_PASSWORD` | `password` | Database admin password |
| `DB_PORT` | `db_port` | PostgreSQL port (default: `5432`) |
| `PORT` | — | App listen port (hardcoded: `3000`) |

### Dockerfile

- Base image: `node:20-alpine`
- Runs as non-root `node` user
- Exposes port `3000`
- Production dependencies only (`npm install --production`)

---

## Helm Chart — myapp

The chart deploys the Node.js REST API connected to PostgreSQL Flexible Server.

| Parameter | Default | Description |
|---|---|---|
| `replicaCount` | `2` | Number of pod replicas |
| `image.repository` | `helmaksacr.azurecr.io/nodeapp` | Container image |
| `image.tag` | `v1` | Image tag |
| `service.type` | `LoadBalancer` | Kubernetes service type |
| `service.port` | `3000` | Service and container port |
| `livenessProbe.httpGet.path` | `/health` | Liveness probe endpoint |
| `readinessProbe.httpGet.path` | `/health` | Readiness probe endpoint |
| `autoscaling.enabled` | `false` | Enable HPA |
| `ingress.enabled` | `false` | Enable Ingress resource |
| `httpRoute.enabled` | `false` | Enable Gateway API HTTPRoute |

The deployment template injects database credentials from the Kubernetes secret `basic-auth` as environment variables (`DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_PORT`, `PORT`).

### Deploy with custom values

```bash
helm install myapp ./myapp -n myapp --create-namespace \
  --set replicaCount=3 \
  --set service.type=LoadBalancer
```

### Upgrade an existing release

```bash
helm upgrade myapp ./myapp -n myapp
```

### Uninstall

```bash
helm uninstall myapp -n myapp
```

> **Note:** Helm releases are namespace-scoped. Always specify `-n myapp` when managing this release.

---

## Networking

| Subnet | CIDR | Purpose |
|---|---|---|
| web | 10.0.1.0/24 | Web-tier resources / Private endpoint |
| app | 10.0.2.0/24 | Application-tier resources |
| database | 10.0.3.0/24 | Database-tier resources |
| aks | 10.0.4.0/24 | AKS node pool |

The AKS cluster uses the **Azure CNI** network plugin with a service CIDR of `10.2.0.0/16` and DNS service IP `10.2.0.10`.

The ACR private endpoint is placed in the **web** subnet with a private DNS zone (`privatelink.azurecr.io`) linked to the VNet, ensuring container image pulls stay within the private network.

The PostgreSQL Flexible Server is deployed with a **delegated subnet** (database subnet) and a private DNS zone (`privatelink.postgres.database.azure.com`) for VNet-integrated name resolution. Public network access is disabled.

---

## Modules Reference

### aks

Provisions an AKS cluster with system-assigned managed identity, assigns the `AcrPull` role to the kubelet identity, and creates a Kubernetes namespace and secret for database credentials.

**Inputs:** `aks_cluster_name`, `location`, `resource_group_name`, `node_count`, `node_vm_size`, `subnet_prefixes`, `subnet_ids`, `acr_id`, `db_host`, `db_name`, `db_user`, `db_password`

**Outputs:** `aks_id`, `host`, `client_certificate`, `client_key`, `cluster_ca_certificate`, `kube_config`, `aks_resource`

**Resources created:**
- `azurerm_kubernetes_cluster` — AKS cluster (Standard tier, Azure CNI)
- `azurerm_role_assignment` — AcrPull role for kubelet identity
- `kubernetes_namespace_v1` — `myapp` namespace
- `kubernetes_secret_v1` — `basic-auth` secret with DB credentials

### compute

Provisions an Azure Container Registry (Premium SKU).

**Inputs:** `acr_name`, `location`, `resource_group_name`

**Outputs:** `acr_id`

### database

Provisions an Azure PostgreSQL Flexible Server with VNet integration and a database.

**Inputs:** `location`, `resource_group_name`, `postgresql_admin_username`, `postgresql_admin_password`, `subnet_ids`, `private_dns_zone_vl_id`

**Resources created:**
- `azurerm_postgresql_flexible_server` — PostgreSQL v12, B_Standard_B1ms SKU, 32GB storage, zone 2
- `azurerm_postgresql_flexible_server_database` — `myappdb` (UTF8, en_US.utf8)

### networking

Provisions a virtual network with four subnets (web, app, database, aks). The database subnet has a delegation for `Microsoft.DBforPostgreSQL/flexibleServers`.

**Inputs:** `location`, `resource_group_name`, `acr_name`, `address_space`, `subnet_prefixes`

**Outputs:** `subnet_ids`, `vnet_id`, `database_subnet`

### private_endpoint

Provisions private DNS zones and endpoints for both ACR and PostgreSQL, linked to the VNet.

**Inputs:** `location`, `resource_group_name`, `acr_id`, `vnet_id`, `subnet_ids`, `database_subnet`

**Outputs:** `private_dns_zone_vl_id` (PostgreSQL DNS zone ID)

**Resources created:**
- `azurerm_private_dns_zone` — `privatelink.azurecr.io` (ACR)
- `azurerm_private_dns_zone` — `privatelink.postgres.database.azure.com` (PostgreSQL)
- `azurerm_private_dns_zone_virtual_network_link` — VNet links for both zones
- `azurerm_private_endpoint` — ACR private endpoint on web subnet

---

## Remote State Backend

Terraform state is stored remotely in Azure Blob Storage for team collaboration and state locking.

| Setting | Value |
|---|---|
| Resource Group | `helmaksdev-rg` |
| Storage Account | `helmaksstatedev` |
| Container | `tfstate` |
| State File Key | `terraform.tfstate` |
| Min TLS Version | 1.2 |
| Versioning | Enabled |
| Delete Retention | 30 days |

Provision the backend first with `cd backend && terraform apply`.

---

## Tear Down

To destroy all resources in the dev environment:

```bash
cd env/dev
terraform destroy
```

To destroy the remote state backend:

```bash
cd backend
terraform destroy
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `ImagePullBackOff` | Image built for wrong platform (ARM64 on Apple Silicon) | Rebuild with `docker build --platform linux/amd64` |
| `CrashLoopBackOff` with exit code 137 | Liveness probe hitting wrong port or path | Ensure `livenessProbe` targets port `3000` and path `/health` |
| `no such host` on `terraform apply` | Stale kubeconfig after infra recreation | Run `az aks get-credentials --overwrite-existing` or re-apply (null_resource handles this) |
| `Cannot GET /` in browser | No root route defined in the app | Use `/health` or `/items` endpoints instead |
| `EmptyPrivateDnsZoneArmResourceId` | DNS zone ID not passed to database module | Verify `private_dns_zone_vl_id` output points to PostgreSQL DNS zone |
| `ConflictingPublicNetworkAccess` | `public_network_access_enabled` conflicts with VNet integration | Set to `false` or remove (depends on provider version) |

---

## Environment Parity

The project is structured for multi-environment deployments. Currently only `dev` is configured. To add `stage` or `prod`:

1. Copy the contents of `env/dev/` into the target environment folder
2. Update `terraform.tfvars` with environment-specific values (cluster name, node count, VM size, etc.)
3. Update `backend.tf` to point to a separate state file key
4. Run `terraform init` and `terraform apply` from the new environment folder

---

## License

This project is provided as-is for educational and demonstration purposes.