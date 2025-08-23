#!/bin/bash

# Usage: ./scripts/deploy-gitlab.sh [registration_token]
# Example: ./scripts/deploy-gitlab.sh glrt-xxxxxxxxxxxxxxxxxxxx

REGISTRATION_TOKEN=$1

echo "Deploying GitLab to Kubernetes..."

# Apply GitLab manifests in order
echo "Creating namespace and storage..."
kubectl apply -f devops/gitlab/00-namespace.yaml

echo "Deploying GitLab..."
kubectl apply -f devops/gitlab/01-gitlab.yaml

echo "Waiting for GitLab to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/gitlab -n gitlab

echo "Deploying GitLab Runner..."
if [ -n "$REGISTRATION_TOKEN" ]; then
    # Replace registration token in runner config
    sed "s/REPLACE_WITH_REGISTRATION_TOKEN/$REGISTRATION_TOKEN/g" \
        devops/gitlab/02-gitlab-runner.yaml | kubectl apply -f -
else
    echo "Warning: No registration token provided. GitLab Runner will need manual registration."
    kubectl apply -f devops/gitlab/02-gitlab-runner.yaml
fi

echo "Creating ingress..."
kubectl apply -f devops/gitlab/03-ingress.yaml

echo "GitLab deployment completed!"
echo ""
echo "Getting GitLab URL..."
kubectl get ingress gitlab-ingress -n gitlab

echo ""
echo "Getting initial root password:"
echo "kubectl exec -it deployment/gitlab -n gitlab -- grep 'Password:' /etc/gitlab/initial_root_password"

echo ""
echo "To get registration token for runners:"
echo "1. Login to GitLab as root"
echo "2. Go to Admin Area > CI/CD > Runners"
echo "3. Copy the registration token"
echo "4. Re-run: ./scripts/deploy-gitlab.sh <token>"
