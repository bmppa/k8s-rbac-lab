#!/bin/bash

set -e  # Exit immediately on error

echo "🚀 Setting up Kubernetes RBAC Test Environment"

# Step 1: Create two namespaces
echo "⌛ Waiting for namespaces to be ready..."
kubectl create -f namespaces.yaml

# Step 2: Create service accounts for users in each namespace
echo "⌛ Waiting for service accounts to be ready..."
kubectl create serviceaccount dev-user -n dev-ns
kubectl create serviceaccount ops-user -n ops-ns

# Step 3: Create Developer Role (Read-Only in dev-ns, No Access to ops-ns)
echo "⌛ Waiting for dev-role to be ready..."
kubectl apply -f dev-role.yaml

# Step 4: Create Operations Role (Full Control Over Deployments in ops-ns, Read-Only in dev-ns)
echo "⌛ Waiting for ops-role to be ready..."
kubectl apply -f ops-role.yaml

# Step 5: Bind Users to Roles
echo "⌛ Waiting for rolebindings to be ready..."
kubectl apply -f rolebindings.yaml

# Step 6: Testing
sleep 2
# dev-user in dev-ns
echo "🚨 Testing dev-user lists pods in dev-ns"
kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n dev-ns || echo "✅ Connection blocked as expected."
kubectl auth can-i list deployments --as=system:serviceaccount:dev-ns:dev-user -n dev-ns
kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n ops-ns

# ops-user in ops-ns
echo "🚨 ops-user in ops-ns"
kubectl auth can-i list deployments --as=system:serviceaccount:ops-ns:ops-user -n ops-ns
kubectl auth can-i create deployments --as=system:serviceaccount:ops-ns:ops-user -n ops-ns
kubectl auth can-i delete deployments --as=system:serviceaccount:ops-ns:ops-user -n ops-ns

# ops-user in dev-ns (read-only)
echo "🚨 ops-user in dev-ns (read-only)"
kubectl auth can-i list deployments --as=system:serviceaccount:ops-ns:ops-user -n dev-ns
kubectl auth can-i delete deployments --as=system:serviceaccount:ops-ns:ops-user -n dev-ns
kubectl auth can-i list pods --as=system:serviceaccount:ops-ns:ops-user -n dev-ns

# CLEANUP
echo "🧹 Cleanup..."
read -p "Delete test namespaces? (y/N): " DEL
if [[ "$DEL" =~ ^[Yy]$ ]]; then
  kubectl delete -f .
  echo "✅ Cleanup completed."
else
  echo "⚠️ Remember to clean up manually with: kubectl delete -f ."
fi
