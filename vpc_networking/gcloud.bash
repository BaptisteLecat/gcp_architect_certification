
gcloud compute firewall-rules list
gcloud compute firewall-rules delete default-allow-icmp default-allow-internal default-allow-rdp default-allow-ssh

gcloud compute networks list
gcloud compute networks delete default

gcloud compute networks update mynetwork --switch-to-custom-subnet-mode