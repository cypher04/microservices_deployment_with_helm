# Microservices Deployment on Azure Kubernetes Service (AKS)

Infrastructure-as-Code project that provisions an AKS cluster on Azure using Terraform and deploys containerised workloads with Helm.

---

## Architecture Overview

```
                        ┌──────────────────────────────────────────────────┐
                        │              Azure Resource Group                │
                        │                                                  │
                        │  ┌──────────────────────────────────────────┐    │
                        │  │        Virtual Network (10.0.0.0/16)     │    │
                        │  │                                          │    │
                        │  │  ┌──────────┐  ┌──────────┐             │    │
                        │  │  │ web      │  │ app      │             │    │
                        │  │  │ subnet   │  │ subnet   │             │    │
                        │  │  │ 10.0.1.0 │  │ 10.0.2.0 │             │    │
                        │  │  └──────────┘  └──────────┘             │    │
                        │  │                                          │    │
                        │  │  ┌──────────┐  ┌──────────────────────┐ │    │
                        │  │  │ database │  │ aks subnet           │ │    │
                        │  │  │ subnet   │  │ 10.0.4.0/24          │ │    │
                        │  │  │ 10.0.3.0 │  │                      │ │    │
                        │  │  └──────────┘  │  ┌────────────────┐  │ │    │
                        │  │                │  │  AKS Cluster    │  │ │    │
                        │  │                │  │  3 Nodes        │  │ │    │
                        │  │                │  │  LoadBalancer:80 │  │ │    │
                        │  │                │  └────────────────┘  │ │    │
                        │  │                └──────────────────────┘ │    │
                        │  └──────────────────────────────────────────┘    │
                        │                                                  │
                        │  ┌──────────────┐  ┌────────────────────────┐   │
                        │  │ ACR          │◄─┤ Private Endpoint       │   │
                        │  │ (Premium)    │  │ + Private DNS Zone     │   │
                        │  └──────────────┘  └────────────────────────┘   │
                        └──────────────────────────────────────────────────┘
```

**Key components:**

| Component | Purpose |
|---|---|
| **AKS Cluster** | Hosts containerised workloads on Kubernetes |
| **Azure Container Registry (ACR)** | Stores and serves container images (Premium SKU) |
| **Virtual Network** | Network isolation with dedicated subnets for web, app, database, and AKS |
| **Private Endpoint** | Secures ACR access over a private link (no public internet) |
| **Private DNS Zone** | Resolves `privatelink.azurecr.io` within the VNet |
| **Helm Chart** | Packages the Kubernetes deployment, service, and supporting resources |

---

## Project Structure

```
.
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
│   │   ├── backend.tf              #     Remote state backend config
│   │   └── outputs.tf              #     Output values
│   ├── stage/                      #   Staging (template — not yet configured)
│   └── prod/                       #   Production (template — not yet configured)
│
├── modules/                        # Reusable Terraform modules
│   ├── aks/                        #   AKS cluster + RBAC role assignment for ACR
│   ├── compute/                    #   Azure Container Registry
│   ├── networking/                 #   VNet + subnets (web, app, database, aks)
│   ├── private_endpoint/           #   Private endpoint + DNS zone for ACR
│   ├── database/                   #   Database (template — not yet implemented)
│   └── security/                   #   Security (template — not yet implemented)
│
├── myapp/                          # Helm chart
│   ├── Chart.yaml                  #   Chart metadata (v0.1.0)
│   ├── values.yaml                 #   Default values (image, replicas, service type)
│   └── templates/                  #   Kubernetes manifests
│       ├── deployment.yaml         #     Deployment with liveness/readiness probes
│       ├── service.yaml            #     Service (LoadBalancer, port 80)
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
- Resource group
- Virtual network with four subnets
- Azure Container Registry (Premium) with a private endpoint
- AKS cluster (3 nodes) with `AcrPull` role assignment
- Helm release of the `myapp` chart
- Automatic kubeconfig refresh via `null_resource` provisioner

### 3. Verify the Deployment

After `terraform apply` completes, the kubeconfig is updated automatically. Verify:

```bash
kubectl get nodes
kubectl get svc -n myapp
```

The service is exposed as a `LoadBalancer` on port 80. It may take a few minutes for the external IP to be assigned.

---

## Helm Chart — myapp

The chart deploys a sample application (`aks-helloworld`) to demonstrate the AKS cluster.

| Parameter | Default | Description |
|---|---|---|
| `replicaCount` | `2` | Number of pod replicas |
| `image.repository` | `mcr.microsoft.com/azuredocs/aks-helloworld` | Container image |
| `image.tag` | `v1` | Image tag |
| `service.type` | `LoadBalancer` | Kubernetes service type |
| `service.port` | `80` | Service port |
| `autoscaling.enabled` | `false` | Enable HPA |
| `ingress.enabled` | `false` | Enable Ingress resource |
| `httpRoute.enabled` | `false` | Enable Gateway API HTTPRoute |

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

---

## Modules Reference

### aks

Provisions an AKS cluster with system-assigned managed identity and assigns the `AcrPull` role to the kubelet identity.

**Inputs:** `aks_cluster_name`, `location`, `resource_group_name`, `node_count`, `node_vm_size`, `subnet_prefixes`, `subnet_ids`, `acr_id`

**Outputs:** `aks_id`, `host`, `client_certificate`, `client_key`, `cluster_ca_certificate`, `kube_config`

### compute

Provisions an Azure Container Registry (Premium SKU).

**Inputs:** `acr_name`, `location`, `resource_group_name`

**Outputs:** `acr_id`

### networking

Provisions a virtual network with four subnets (web, app, database, aks).

**Inputs:** `location`, `resource_group_name`, `acr_name`, `address_space`, `subnet_prefixes`

**Outputs:** `subnet_ids`, `vnet_id`

### private_endpoint

Provisions a private DNS zone and private endpoint for the ACR, linked to the VNet.

**Inputs:** `location`, `resource_group_name`, `acr_id`, `vnet_id`, `subnet_ids`

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

## Environment Parity

The project is structured for multi-environment deployments. Currently only `dev` is configured. To add `stage` or `prod`:

1. Copy the contents of `env/dev/` into the target environment folder
2. Update `terraform.tfvars` with environment-specific values (cluster name, node count, VM size, etc.)
3. Update `backend.tf` to point to a separate state file key
4. Run `terraform init` and `terraform apply` from the new environment folder

---

## License

This project is provided as-is for educational and demonstration purposes.