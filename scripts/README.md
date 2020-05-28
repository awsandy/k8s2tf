# k8s2tf

## Prereqs

* An EKS cluster
* kubectl installed with admin access
* Terraform v 12.24+

## Usage

./k82tf.sh 

## Kubernetes Providers Covered


* kubernetes_cluster_role
* kubernetes_cluster_role_binding
* kubernetes_config_map
* kubernetes_daemonset
* kubernetes_deployment
* kubernetes_endpoints
* kubernetes_ingres
* kubernetes_horizontal_pod_autoscaler
* kubernetes_job
* kubernetes_namespace
* kubernetes_network_policy
* kubernetes_pod
* kubernetes_role
* kubernetes_role_binding
* kubernetes_service
* kubernetes_service_account

### partial (difficulties)

* kubernetes_secret

## To do 
* kubernetes_api_service 
* kubernetes_cron_job
* kubernetes_limit_range
* kubernetes_persistent_volume
* kubernetes_persistent_volume_claim
* kubernetes_pod_disruption_budget
* kubernetes_priority_class
* kubernetes_replication_controller
* kubernetes_resource_quota
* kubernetes_stateful_set
* kubernetes_storage_class