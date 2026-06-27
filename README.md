# Cloud Security Engineering Project 05: Zero-Trust EKS Fortress (Runtime Isolation & Micro-Segmented Network Governance)

## Overview

I have architected and deployed a highly secure, zero-trust container runtime environment on AWS EKS using modern Infrastructure as Code primitives and defense-in-depth networking. This project establishes an airtight Kubernetes infrastructure footprint by leveraging EKS Auto Mode with strictly scoped identity models, locking control plane API endpoints down to administrative IP spaces, and enforcing native, pod-level packet filtering. By replacing open-network defaults with strict namespace-wide isolation barriers, the architecture stops lateral attack propagation, resolves internal service discovery gaps, and guarantees that application communication loops exist strictly over explicitly authorized, unidirectional pathways.

## The Problem

Default Kubernetes cluster deployments and flat cloud networking models inherently prioritize connectivity over isolation, leaving container environments vulnerable to extensive operational risk:

* **Unrestricted Lateral Propagation:** In a standard Kubernetes namespace, the cluster network is completely flat. If an attacker compromises a single internet-facing frontend application pod, they can move laterally without obstruction, scanning internal cluster networks and accessing high-value backend databases or internal APIs.

* **Over-Privileged Identity Configurations:** Transitioning to automated container compute models often results in IAM role configuration drift. Provisioning multi-tenant compute fleets without defining granular session token structures allows underlying hosts to inherit ambient cloud permissions beyond their immediate operational scope.

* **Core Internal Service Discovery Gaps:** Implementing standard default-deny network security rules blindly inside a cluster breaks core internal service discovery (CoreDNS). Pods become isolated in a total network vacuum, unable to parse service hostnames, resulting in systemic workload crashes and application communication failures.

## The Solution

* **Top-Level CNI Packet Filtering:** Activated the native AWS VPC CNI Network Policy engine, moving away from legacy overlay configurations and establishing hardware-level packet inspection directly on the worker node interfaces.

* **Namespace-Wide Traffic Blackholing:** Implemented a global Default Deny-All network policy layer. This instantly revokes all ambient ingress and egress capabilities from every container workload, forcing a zero-trust communication baseline.

* **Unidirectional Tunneling and DNS Resolution:** Engineered explicit, highly specific Ingress and Egress micro-segmentation policies. This included mapping a dedicated Egress policy to the frontend compute tier that explicitly authorizes out-of-band UDP/TCP Port 53 data streams to the CoreDNS nameservers while routing authorized port 80 application traffic to the backend layer.

* **Auto Mode Principle of Least Privilege:** Integrated modern EKS Auto Mode trust relationships using the sts:TagSession action, binding the automated control plane securely to specific AWS-managed node policies.

## Tech Stack

* **Orchestration Control Plane:** Amazon Elastic Kubernetes Service (EKS v1.30+ Auto Mode)

* **Network & Security Engine:** AWS VPC CNI (Native Network Policy Engine Enabled)

* **Compute Fleets:** Managed EC2 Node Groups (t3.medium Architecture / Linux Runtimes)

* **Cluster Management Engine:** Kubectl CLI Control System

* **Infrastructure as Code:** Terraform (v1.5+ Declarative Flat-File Syntax)

* **Diagnostic Toolchain:** Nicolaka/Netshoot (Cloud-Native Network Interrogation Suite)

## Architecture Diagram

<img width="1170" height="828" alt="Architecture Diagram" src="https://github.com/user-attachments/assets/0fb3f18c-7e12-4ed4-9157-25c63df2181b" />


## Project Procedure

### 1. Control Plane IAM Scoping & EKS Auto Mode Bootstrapping

I established the foundational security framework for the EKS control plane by configuring an IAM Role tailored for modern EKS Auto Mode features. I augmented the traditional cluster trust relationship to handle advanced automated compute tasks by embedding the sts:TagSession action capability.

I then bound the identity directly to the mandatory AWS-managed policy tree required to govern compute, storage, load balancing, and network routing natively:

* AmazonEKSClusterPolicy

* AmazonEKSBlockStoragePolicy

* AmazonEKSComputePolicy

* AmazonEKSLoadBalancingPolicy

* AmazonEKSNetworkingPolicy

### 2. Compute Plane Isolation & Advanced Endpoint Configuration

I deployed the EKS control plane cluster into a custom network architecture. To protect the cluster control center from global internet footprint scanners, I configured the cluster endpoint access parameters to Public and private. I then implemented an advanced networking override rule, restricting public access to the API control plane exclusively to my authenticated local management IP CIDR block via the AWS Console interface.

### 3. AWS VPC CNI Network Policy Engine Activation

Once the cluster transitioned to an Active state, I synchronized my local terminal environment with the active cloud infrastructure endpoint:

```bash
aws eks update-kubeconfig --region us-east-1 --name zero-trust-cluster
```

By default, network policies are disabled within the VPC CNI. To turn on native packet filtering directly on the node interfaces without installing heavy third-party software, I executed a top-level add-on creation configuration command using the modern EKS JSON schema:

```bash
aws eks create-addon \
  --cluster-name zero-trust-cluster \
  --addon-name vpc-cni \
  --configuration-values '{"enableNetworkPolicy": "true"}' \
  --resolve-conflicts OVERWRITE
```

### 4. Runtime Micro-Segmentation (The Zero-Trust Simulation)

To simulate a multi-tier application environment, I spun up an NGINX backend application layer:

```bash
kubectl run backend --image=nginx --labels="app=backend" --expose --port=80
```

To prevent container runtime compatibility exceptions caused by strict containerd engine constraints rejecting deprecated image schemas, I utilized a modern, cloud-native network diagnostics image (nicolaka/netshoot) to act as the frontend testing tier.

The Blackhole (Enforcing Default-Deny):

I dropped a global blocking mesh over the default namespace, cutting off all communication lines to isolate every pod:

```bash
cat << 'EOF' > default-deny.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

kubectl apply -f default-deny.yaml
```

The Pinhole (Granular Ingress & Egress Engineering):

With everything blocked, the frontend pod could no longer resolve service addresses via CoreDNS or connect to the backend. To restore authorized operational traffic securely, I punched two precise, unidirectional holes through the firewall mesh.

First, I authorized the backend pod to accept traffic from the frontend on port 80:

```bash
cat << 'EOF' > allow-backend-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-ingress
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

kubectl apply -f allow-backend-ingress.yaml
```

Second, I authored a comprehensive Egress policy for the frontend. This explicitly allowed it to hit CoreDNS in the kube-system namespace over UDP/TCP port 53 for service lookup, and allowed outbound data flow to the backend pod on port 80:

```bash
cat << 'EOF' > frontend-egress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
EOF

kubectl apply -f frontend-egress.yaml
```

## Infrastructure as Code (IaC) Architecture

To guarantee exact environment repeatability, prevent state drift, and eliminate manual console interaction entirely, the complete zero-trust platform is codified using modular Terraform files.

## Directory Layout & Modular Structure

```text
eks-kubernetes-fortress-runtime-isolation/
├── provider.tf          # Configures AWS provider limits and global environment tags
├── variables.tf         # Abstracted input structures for network CIDRs and admin IPs
├── vpc.tf               # Provisions custom multi-AZ subnets, NAT systems, and EKS route tags
├── iam.tf               # Handles Control Plane Auto Mode roles and Node execution policies
├── eks_cluster.tf       # Orchestrates the EKS master cluster with strict public/private CIDR blocks
├── eks_nodes.tf         # Provisions worker node groups confined entirely to private subnets
└── outputs.tf           # Exports cluster endpoints and automatic update-kubeconfig terminal links
```

## Detailed File-by-File Technical Breakdown

### System Provider Scoping (`provider.tf`)

Initializes the AWS cloud provider plugin constraint tree to version ~> 5.0 and applies unified corporate tags to every single private subnet, role attachment, and route.

### Variable Abstractions (`variables.tf`)

Manages regional alignment properties, custom sub-network blocks, and your secure administrative public IP string to keep the rest of the execution engine reusable.

### Isolated Network Fabric (`vpc.tf`)

Builds a custom VPC completely isolated from the default AWS footprint. Creates public subnets for edge routing, a NAT Gateway tied to an Elastic IP, and sets up explicit internal routing tables. Applies the mandatory kubernetes.io/role/internal-elb = 1 and kubernetes.io/role/elb = 1 tagging parameters.

### Zero-Trust Access Control (`iam.tf`)

Programmatically constructs the custom cluster execution identity, injecting the modern sts:TagSession parameter into the assume role JSON block. Automatically loops and attaches the five required EKS Auto Mode service policies.

### Kubernetes Orchestration Control (`eks_cluster.tf & eks_nodes.tf`)

Establishes the core cluster API control center with endpoint access configured strictly to public/private, restricted down to the admin IP variable block. Simultaneously spawns the managed worker node group fleet, attaching them purely to the private subnet IDs to keep the hosts completely invisible to the public internet.

## Verification and Results

### 1. Active Perimeter Firewall Verification

**What this shows:** The EKS cluster configuration console screen and terminal connectivity tests.

**Technical Proof:** Confirms that public access to the cluster control plane API endpoint is restricted to the specific administrative IP CIDR block. Attempts to query the API from unauthorized network locations are dropped with an explicit i/o timeout block, proving the outer defensive boundary is working.

### 2. Verified Workload Isolation (The Red Build Test)

**What this shows:** The terminal log output of a netshoot testing pod inside the default namespace after applying the default-deny-all policy.

**Technical Proof:** Demonstrates that executing curl --connect-timeout 5 backend results in an immediate execution halt and failure. This proves that the AWS VPC CNI network policy engine is actively dropping unverified packets, successfully trapping the container inside a zero-trust vacuum.

### 3. Verified Secure Communication & DNS Resolution (The Green Build Test)

**What this shows:** The terminal log output of the netshoot pod after applying the granular ingress and egress files.

**Technical Proof:** Validates that executing curl backend immediately resolves the service address and returns the complete NGINX HTML success page. This confirms that the cluster successfully parsed the internal DNS records over UDP port 53 and established a secure, authorized micro-segmented connection over TCP port 80.

### 4. Infrastructure-As-Code Integrity Execution

**What this shows:** The terminal command-line interface output of a terraform plan and terraform apply loop.

**Technical Proof:** Confirms that the entire VPC routing matrix, security boundaries, cluster definitions, and IAM profiles compile cleanly on a single automated run list with zero errors or manual console overrides.

## Verification Screenshots

### 1. EKS Control Plane Public Endpoint Allowlist Restriction

This screenshot displays the AWS EKS Management Console networking panel for zero-trust-cluster. It verifies that Cluster endpoint access is configured as Public and private, with the Advanced settings allowlist locked down to a single specific administrative IP address (/32). This proves that the global internet cannot discover or run brute-force exploits against the cluster control plane API.

<img width="1909" height="783" alt="Screenshot 1" src="https://github.com/user-attachments/assets/5c658b9d-c428-421b-b7d4-6abf041fd8b5" />

### 2. Verified Workload Isolation via Default-Deny Policy

This screenshot captures the terminal output after applying the `default-deny-all` Kubernetes NetworkPolicy. It shows a `curl` request from the frontend diagnostics pod attempting to reach the backend service, but the traffic is blocked by the active default-deny rule and returns an `i/o timeout`. This proves that unauthorized pod-to-pod communication is successfully blackholed inside the namespace.

<img width="1806" height="174" alt="Screenshot 2" src="https://github.com/user-attachments/assets/8f76ffbc-f9ae-49c1-b3be-53f8cffc4897" />


### 3. Verified Secure Micro-Segmentation and Service Discovery Success

This screenshot captures the terminal window showing successful network resolution. After the application of the frontend-egress and allow-backend-ingress policy structures, the frontend pod successfully reaches out to CoreDNS over UDP Port 53, parses the service directory structure, and maps an active connection to the backend over TCP Port 80, returning the complete raw "Welcome to nginx!" HTML body.

<img width="1611" height="386" alt="Screenshot 3" src="https://github.com/user-attachments/assets/e6dca0f7-f945-49ed-87cf-2a133c6e4dcf" />


### 4. IAM Cluster Management Role with Auto Mode Identity Maps

This screenshot showcases the AWS IAM Management Console interface detailing the EKS-Fortress-ControlPlane-Role. It explicitly highlights the attached policy ledger, proving that the identity holds the advanced managed blocks (AmazonEKSComputePolicy, AmazonEKSBlockStoragePolicy, etc.) alongside an updated Trust Relationship configuration that contains the mandatory sts:TagSession action string required by modern EKS Auto Mode architectures.

<img width="1381" height="549" alt="Screenshot 4" src="https://github.com/user-attachments/assets/54192e98-5a65-4691-a4bc-48ddc479394c" />


## Future Improvements

* **Automated GitOps Reconciliation:** Integrate a continuous deployment agent such as ArgoCD to monitor a secure Git repository, automatically tracking and syncing network policy updates to the live cluster workspace without manual human interaction.

* **Mutual TLS Pod Encryption:** Deploy an istio or Linkerd service mesh wrapper across the cluster namespaces to enforce mutual TLS (mTLS) cryptographic encryption on all pod-to-pod data streams on top of network policy rules.

* **Automated Compliance Scanning:** Integrate Kube-bench and Trivy-operator checks inside the cluster node initialization sequences to automatically cross-verify host runtimes against standard CIS Kubernetes Security Benchmarks.

## Notes

**Bottom Line:** The Zero-Trust EKS Fortress project transitions modern container orchestration deployments into an airtight runtime environment. By isolating the compute worker fleet entirely within private network lanes, restricting control plane access to verified management IPs, leveraging the AWS VPC CNI to enforce strict default-deny packet filtering, and mapping explicit, label-based pinholes for core application and DNS streams, the architecture delivers complete runtime protection and eliminates the risk of lateral data breaches.
