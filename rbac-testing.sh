#!/bin/bash

echo "🚨 Testing: dev-user lists pods in dev-ns"
if [ $(kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n dev-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: echo dev-user lists pods in ops-ns"
if [ $(kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n ops-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: dev-user lists pods in kube-system"
if [ $(kubectl auth can-i list pods --as=system:serviceaccount:dev-ns:dev-user -n kube-system) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: dev-user creates deployments in dev-ns"
if [ $(kubectl auth can-i create deploy --as=system:serviceaccount:dev-ns:dev-user -n dev-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: dev-user creates deployments in ops-ns" || echo "❌ Action denied."
if [ $(kubectl auth can-i create deploy --as=system:serviceaccount:dev-ns:dev-user -n ops-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: dev-user creates deployments in kube-system"
if [ $(kubectl auth can-i create deploy --as=system:serviceaccount:dev-ns:dev-user -n kube-system) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: ops-user lists deployments in ops-ns"
if [ $(kubectl auth can-i list deploy --as=system:serviceaccount:ops-ns:ops-user -n ops-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: ops-user lists deployments in dev-ns"
if [ $(kubectl auth can-i list deploy --as=system:serviceaccount:ops-ns:ops-user -n dev-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: ops-user lists deployments in kube-system"
if [ $(kubectl auth can-i list deploy --as=system:serviceaccount:ops-ns:ops-user -n kube-system) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: ops-user create pods in ops-ns"
if [ $(kubectl auth can-i create pods --as=system:serviceaccount:ops-ns:ops-user -n ops-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: ops-user create pods in dev-ns"
if [ $(kubectl auth can-i create pods --as=system:serviceaccount:dev-ns:dev-user -n dev-ns) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

echo "🚨 Testing: ops-user create pods in kube-system"
if [ $(kubectl auth can-i create pods --as=system:serviceaccount:ops-ns:ops-user -n kube-system) == "yes" ]; then
  echo "✅ Action allowed."
  else
  echo "❌ Action denied."
fi

