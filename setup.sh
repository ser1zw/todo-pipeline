#!/bin/sh

oc login -u admin -p admin
sleep 3

oc apply -f yaml/00_install_tekton.yaml
sleep 10

oc new-project ogwtest
sleep 3

oc create -f yaml/01_apply_manifest_task.yaml
sleep 3

oc create -f yaml/02_update_deployment_task.yaml
sleep 3

oc create -f yaml/03_persistent_volume_claim.yaml
sleep 3

oc create -f yaml/04_pipeline.yaml
sleep 3

tkn pipeline start build-and-deploy \
  -w name=shared-workspace,claimName=source-pvc \
	-p deployment-name=todo-app \
	-p git-url=https://github.com/ser1zw/todo.git \
	-p git-revision=main \
	-p IMAGE=image-registry.openshift-image-registry.svc:5000/ogwtest/todo-api
sleep 30

oc new-app postgresql-ephemeral \
  -p NAMESPACE=openshift \
  -p DATABASE_SERVICE_NAME=todo-db \
  -p POSTGRESQL_USER=postgres \
  -p POSTGRESQL_PASSWORD=postgres \
  -p POSTGRESQL_DATABASE=todo-db \
  -p POSTGRESQL_VERSION=latest
sleep 30

wget https://raw.githubusercontent.com/ser1zw/todo/main/src/main/resources/sql/schema.sql
podname=$(oc get pods -o custom-columns=POD:.metadata.name --no-headers -l name='todo-db')
oc exec $podname -- psql -U postgres -c "$(cat schema.sql);"
