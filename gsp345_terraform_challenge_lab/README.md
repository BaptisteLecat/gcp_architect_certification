# Build Infrastructure with Terraform on Google Cloud : Challenge Lab

https://partner.cloudskillsboost.google/paths/77/course_templates/636/labs/464836

## Objectives

- Import existing infrastructure into your Terraform configuration.
- Build and reference your own Terraform modules.
- Add a remote backend to your configuration.
- Use and implement a module from the Terraform Registry.
- Re-provision, destroy, and update infrastructure.
- Test connectivity between the resources you've created.


## Exemple of terraform.tfvars

```hcl
project          = "qwiklabs-gcp-04-4518ea4d5f3d"
region           = "us-west1"
zone             = "us-west1-a"
credentials_file = "service.json"
instance_ids = ["8799077920212134395", "8522825924381125115"]
instance_names = ["tf-instance-1", "tf-instance-2"]
instance_machine_types = ["e2-micro", "e2-micro"]
instance_images = ["debian-cloud/debian-11", "debian-cloud/debian-11"]
instance_networks = ["default", "default"]
instance_subnetworks = ["default", "default"]
bucket_name = "tf-bucket-012858"
network_name = "tf-vpc-265932"
```