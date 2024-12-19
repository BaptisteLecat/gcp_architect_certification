# GSP007 - Set Up Network and HTTP Load Balancers

---

## Objective

The purpose of this Terraform project is to deploy and configure both **Network Load Balancers (NLB)** and **HTTP Application Load Balancers (ALB)** on Google Cloud. The project demonstrates how to distribute incoming traffic efficiently across multiple backend services using Compute Engine instances.

### Key Features:
- **Network Load Balancer (NLB)**: Operates at Layer 4 (TCP) for efficient and fast packet routing.
- **Application Load Balancer (ALB)**: Operates at Layer 7 (HTTP), offering advanced request routing and scalability.
- Automatic deployment of web server instances with Apache, configured via metadata startup scripts.
- Creation of managed instance groups (MIGs) for scaling and high availability.
- Integration of health checks to ensure only healthy instances receive traffic.
- Firewall rules to allow HTTP traffic and health check probes.

### Note
The following Terraform resource for creating a global static IP does not work due to limitations in Terraform at the time of writing:

```hcl
resource "google_compute_global_address" "static" { 
  name          = "lb-ipv4-1"
  address_type  = "EXTERNAL"
  ip_version = "IPV4"
}
```

To resolve this, you must manually create the static IP via the `gcloud` CLI **before** running `terraform apply`:

```bash
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global
```