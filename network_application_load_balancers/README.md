# GSP007 - Set Up Network and HTTP Load Balancers

This instruction doesn't work:

```hcl
resource "google_compute_global_address" "static" { 
  name          = "lb-ipv4-1"
  address_type  = "EXTERNAL"
  ip_version = "IPV4"
}
```

So we have to run this command before apply :

```bash
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global
```
