# k8s2tf

## Prereqs

* An EKS cluster
* kubectl installed with admin access
* Terraform v 1.1.0+

## Usage

./k82tf.sh <cluster name>

## Kubernetes Providers Covered


* kubernetes_cluster_role_v1
* kubernetes_cluster_role_binding_v1
* kubernetes_config_map_v1
* kubernetes_daemonset_v1
* kubernetes_deployment_v1
* kubernetes_endpoints
* kubernetes_ingress_v1
* kubernetes_horizontal_pod_autoscaler_v1
* kubernetes_job_v1
* kubernetes_namespace_v1
* kubernetes_network_policy_v1
* kubernetes_role_v1
* kubernetes_role_binding_v1
* kubernetes_service_v1
* kubernetes_service_account_v1
* kubernetes_stateful_set_v1

### partial (difficulties)

* kubernetes_secret_v1

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
* kubernetes_storage_class