gcloud container clusters create nucleus-cluster \
    --zone us-west3-b \
    --machine-type n1-standard-1 \
    --num-nodes 3

gcloud container clusters get-credentials nucleus-cluster --zone us-west3-b

kubectl create deployment nucleus-server --image=gcr.io/google-samples/hello-app:2.0

kubectl expose deployment nucleus-server --type=LoadBalancer --port 80 --target-port 8083