 #!/bin/bash

 #Create Cluster
 eksctl create cluster \
  --name test-cluster \
  --region eu-west-1 \
  #--nodegroup-name linux-nodes \
  #--node-type t2.micro \
  #--nodes 2

#Get IAM Load Balancer Controler Policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/install/iam_policy.json

#Create IAM Load Balancer Controler Policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicyTest \
    --policy-document file://iam_policy.json

#Associate IAM OIDC Provider with EKS Cluster
eksctl utils associate-iam-oidc-provider \
  --region=eu-west-1 \
  --cluster=test-cluster \
  --approve

#Create IAM Service Account with Load Balancer Controler Policy
eksctl create iamserviceaccount \
  --cluster=test-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::878598450595:policy/AWSLoadBalancerControllerIAMPolicyTest \
  --override-existing-serviceaccounts \
  --approve

#Check to see if AWS ALB Ingress Controller for Kubernetes is installed
kubectl get deployment -n kube-system alb-ingress-controller

#If AWS ALB Ingress Controller for Kubernetes is installed, uninstall
#kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.8/docs/examples/alb-ingress-controller.yaml
#kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.8/docs/examples/rbac-role.yaml

#Install AWS Load Balancer Controller using Helm V3
helm repo add eks https://aws.github.io/eks-charts

helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=test-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
  --set image.repository=602401143452.dkr.ecr.eu-west-1.amazonaws.com/amazon/aws-load-balancer-controller 

#Verify that the controller is installed
kubectl get deployment -n kube-system aws-load-balancer-controller

#Change context to namespace
kubectl config set-context --current --namespace=hello-world 

#Deploy 2048 game in public subnet
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/examples/2048/2048_full.yaml

#Get Ingress Url
kubectl get ingress/ingress-2048 -n game-2048

#Get Only Ingress Url
kubectl get ingress/ingress-2048 -n game-2048 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

#Delete Cluster Stack
eksctl delete cluster test-cluster

#503 Service Temporarily Unavailable
kubectl config set-context --current --namespace=hello-world 

kubectl exec -it <podname> -n <namespace> -- /bin/bash