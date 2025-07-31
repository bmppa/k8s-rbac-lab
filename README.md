# **Step-by-Step Scenario for Testing RBAC in Kubernetes**

## ✅ **Test Cases**

| #  | Test Scenario                                   | Expected Outcome             |
| -- | ------------------------------------------------| -----------------------------|
| 1  | `dev-user` lists pods in `dev-ns`               | ✅ Allowed                   |
| 2  | `dev-user` lists pods in `ops-ns`               | ❌ Forbidden                 |
| 3  | `dev-user` lists pods in `kube-system`          | ❌ Forbidden                 |
| 4  | `dev-user` creates deployments in `dev-ns`      | ❌ Forbidden                 |
| 5  | `dev-user` creates deployments in `ops-ns`      | ❌ Forbidden                 |
| 6  | `dev-user` creates deployments in `kube-system` | ❌ Forbidden                 |
| 7  | `ops-user` lists deployments in `ops-ns`        | ✅ Allowed                   |
| 8  | `ops-user` lists deployments in `dev-ns`        | ✅ Allowed                   |
| 9  | `ops-user` lists deployments in `kube-system`   | ❌ Forbidden                 |
| 10 | `ops-user` creates pods in `ops-ns`             | ❌ Forbidden                 |
| 11 | `ops-user` creates pods in `dev-ns`             | ❌ Forbidden                 |
| 12 | `ops-user` creates pods in `kube-system`        | ❌ Forbidden                 |

## 🏗️ **Setup**

Create `namespaces.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ops-ns
---
apiVersion: v1                          
kind: Namespace
metadata:
  name: dev-ns
```

Apply:

```sh
kubectl apply -f namespaces.yaml
```

Create `serviceaccounts.yaml`:

```yaml
apiVersion: v1                          
kind: ServiceAccount
metadata:
  name: dev-user
  namespace: dev-ns
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ops-user
  namespace: ops-n
```

Apply:

```sh
kubectl apply -f serviceaccounts.yaml
```


## **Define RBAC Roles Across Namespaces**

### **Developer Role (Read-Only in dev-ns, No Access to ops-ns, No Access to kube-system)**

Create `dev-role.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev-ns
  name: dev-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

Apply:

```sh
kubectl apply -f dev-role.yaml
```

### **Operations Role (Full Control Over Deployments in ops-ns, Read-Only in dev-ns, No Access to kube-system)**

Create `ops-role.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: ops-ns
  name: ops-role
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev-ns
  name: ops-readonly
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
```

Apply:

```sh
kubectl apply -f ops-role.yaml
```

## **Bind Users to Roles**

Create `rolebindings.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: dev-ns
  name: dev-binding
subjects:
- kind: ServiceAccount
  name: dev-user
  namespace: dev-ns
roleRef:
  kind: Role
  name: dev-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: ops-ns
  name: ops-binding
subjects:
- kind: ServiceAccount
  name: ops-user
  namespace: ops-ns
roleRef:
  kind: Role
  name: ops-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: dev-ns
  name: ops-readonly-binding
subjects:
- kind: ServiceAccount
  name: ops-user
  namespace: ops-ns
roleRef:
  kind: Role
  name: ops-readonly
  apiGroup: rbac.authorization.k8s.io
```

Apply:

```sh
kubectl apply -f rolebindings.yaml
```

## **Test Plan for Roles**

### **Objective**

Verify user permissions across namespaces and cluster.

## 🧪 **Test Execution Commands**

Run each test using:

```bash
kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<user> -n <target-namespace>
```

Create `cross-namespace-rbac-test.sh`:

```sh
#!/bin/bash

echo "🔹 Testing: dev-user lists pods in dev-ns"
if [ $(kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n dev-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: dev-user lists pods in ops-ns"
if [ $(kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n ops-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: dev-user lists pods in kube-system"
if [ $(kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n kube-system) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: dev-user creates deployments in dev-ns"
if [ $(kubectl auth can-i create deploy --as=system:serviceaccount:dev-ns:dev-user -n dev-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: dev-user creates deployments in ops-ns" || echo "❌ Action denied."
if [ $(kubectl auth can-i create deploy --as=system:serviceaccount:dev-ns:dev-user -n ops-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: dev-user creates deployments in kube-system"
if [ $(kubectl auth can-i create deploy --as=system:serviceaccount:dev-ns:dev-user -n kube-system) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: ops-user lists deployments in ops-ns"
if [ $(kubectl auth can-i list deploy --as=system:serviceaccount:ops-ns:ops-user -n ops-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: ops-user lists deployments in dev-ns"
if [ $(kubectl auth can-i list deploy --as=system:serviceaccount:ops-ns:ops-user -n dev-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: ops-user lists deployments in kube-system"
if [ $(kubectl auth can-i list deploy --as=system:serviceaccount:ops-ns:ops-user -n kube-system) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: ops-user create pods in ops-ns"
if [ $(kubectl auth can-i create pods --as=system:serviceaccount:ops-ns:ops-user -n ops-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: ops-user create pods in dev-ns"
if [ $(kubectl auth can-i create pods --as=system:serviceaccount:dev-ns:dev-user -n dev-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🔹 Testing: ops-user create pods in kube-system"
if [ $(kubectl auth can-i create pods --as=system:serviceaccount:ops-ns:ops-user -n kube-system) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi
```

---
## 🏗️ **ClusterRole-Based Access**

### 🔹 ClusterRole: View All Pods in All Namespaces

This role grants read access to Pods **cluster-wide**.

Create `clusterrole-view-pods.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: view-all-pods
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

Apply:

```sh
kubectl apply -f clusterrole-view-pods.yaml
```

### 🔹 ClusterRole: Manage Deployments in All Namespaces

Grants full access to Deployments across the cluster.

Create `clusterrole-manage-deployments.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: manage-all-deployments
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "delete"]
```

Apply:

```sh
kubectl apply -f clusterrole-manage-deployments.yaml
```

## 🔗 **ClusterRoleBindings: Bind to ServiceAccounts**

### 🔸 Bind `dev-user` to `view-all-pods` ClusterRole and Bind `ops-user` to `manage-all-deployments` ClusterRole

Create `clusterrolebindings.yaml`

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dev-view-all-pods
subjects:
- kind: ServiceAccount
  name: dev-user
  namespace: dev-ns
roleRef:
  kind: ClusterRole
  name: view-all-pods
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ops-manage-all-deployments
subjects:
- kind: ServiceAccount
  name: ops-user
  namespace: ops-ns
roleRef:
  kind: ClusterRole
  name: manage-all-deployments
  apiGroup: rbac.authorization.k8s.io
```

Apply:

```sh
kubectl apply -f clusterrolebindings.yaml
```

## 🧪 **Test Execution Commands**

Run the same test as before. You should obtain the following results:

| #  | Test Scenario                                   | Expected Outcome             |
| -- | ------------------------------------------------| -----------------------------|
| 1  | `dev-user` lists pods in `dev-ns`               | ✅ Allowed                   |
| 2  | `dev-user` lists pods in `ops-ns`               | ✅ Allowed (via ClusterRole) |
| 3  | `dev-user` lists pods in `kube-system`          | ✅ Allowed (via ClusterRole) |
| 4  | `dev-user` creates deployments in `dev-ns`      | ❌ Forbidden                 |
| 5  | `dev-user` creates deployments in `ops-ns`      | ❌ Forbidden                 |
| 6  | `dev-user` creates deployments in `kube-system` | ❌ Forbidden                 |
| 7  | `ops-user` lists deployments in `ops-ns`        | ✅ Allowed                   |
| 8  | `ops-user` lists deployments in `dev-ns`        | ✅ Allowed                   |
| 9  | `ops-user` lists deployments in `kube-system`   | ✅ Allowed (via ClusterRole) |
| 10 | `ops-user` creates pods in `ops-ns`             | ❌ Forbidden                 |
| 11 | `ops-user` creates pods in `dev-ns`             | ❌ Forbidden                 |
| 12 | `ops-user` creates pods in `kube-system`        | ❌ Forbidden                 |

---

## 🧹 Cleanup

```sh
kubectl delete clusterrole view-all-pods
kubectl delete clusterrole manage-all-deployments
kubectl delete clusterrolebinding dev-view-all-pods
kubectl delete clusterrolebinding ops-manage-all-deployments
kubectl delete namespace dev-ns
kubectl delete namespace ops-ns
```
