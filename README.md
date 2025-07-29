## **Step-by-Step Scenario for Testing RBAC in Kubernetes**

### **Setup**

Create two namespaces:

```sh
kubectl create namespace dev-ns
kubectl create namespace ops-ns
```

Create service accounts for users in each namespace:

```sh
kubectl create serviceaccount dev-user -n dev-ns
kubectl create serviceaccount ops-user -n ops-ns
```

---

## **Define RBAC Roles Across Namespaces**

### **Developer Role (Read-Only in dev-ns, No Access to ops-ns)**

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

### **Operations Role (Full Control Over Deployments in ops-ns, Read-Only in dev-ns)**

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

---

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

---

## **Test Plan for RBAC Policies Across Namespaces**

### **Objective**

Verify user permissions across two namespaces.

### **Test Cases**

| Test Case                                  | Expected Outcome      |
| ------------------------------------------ | --------------------- |
| `dev-user` lists pods in `dev-ns`          | ✅ Allowed             |
| `dev-user` lists deployments in `dev-ns`   | ❌ Forbidden           |
| `dev-user` lists pods in `ops-ns`          | ❌ Forbidden           |
| `ops-user` lists deployments in `ops-ns`   | ✅ Allowed             |
| `ops-user` creates deployments in `ops-ns` | ✅ Allowed             |
| `ops-user` deletes deployments in `ops-ns` | ✅ Allowed             |
| `ops-user` lists deployments in `dev-ns`   | ✅ Allowed (Read-Only) |
| `ops-user` deletes deployments in `dev-ns` | ❌ Forbidden           |
| `ops-user` lists pods in `dev-ns`          | ❌ Forbidden           |

---

## **Test Execution**

Run tests using `kubectl auth can-i`:

```sh
# dev-user in dev-ns
kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n dev-ns
kubectl auth can-i list deployments --as=system:serviceaccount:dev-ns:dev-user -n dev-ns
kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n ops-ns

# ops-user in ops-ns
kubectl auth can-i list deployments --as=system:serviceaccount:ops-ns:ops-user -n ops-ns
kubectl auth can-i create deployments --as=system:serviceaccount:ops-ns:ops-user -n ops-ns
kubectl auth can-i delete deployments --as=system:serviceaccount:ops-ns:ops-user -n ops-ns

# ops-user in dev-ns (read-only)
kubectl auth can-i list deployments --as=system:serviceaccount:ops-ns:ops-user -n dev-ns
kubectl auth can-i delete deployments --as=system:serviceaccount:ops-ns:ops-user -n dev-ns
kubectl auth can-i list pods --as=system:serviceaccount:ops-ns:ops-user -n dev-ns
```

---

## **Cleanup**

```sh
kubectl delete namespace dev-ns
kubectl delete namespace ops-ns
```
