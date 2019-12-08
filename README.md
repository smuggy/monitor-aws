# Setup Utility Cluster
This cluster contains a set of services to provide the following capabilities in AWS:

  * Monitor capture service (Prometheus)
  * Dashboard and graphing of monitored data (Grafana)
  * Alert management (AlertManager)
  * Service Discovery and Configuration Management (Consul)

These services are setup using Terraform and Ansible. The VPC is assumed to be already setup as is the key
to access the nodes. Linux service accounts are created for each of the services.

An nginx proxy is setup to provide access external to the VPC. The services communicate amongst themselves via
the private ips. The first three services specified and the nginx proxy are set up on one node. The Consul
service is created as a cluster of three nodes across three availability zones in the us-east-2 region.

Two security groups are created, the first for the consul cluster and the second for all other services. 
The Consul nodes do have an EBS volume attached (to /var/lib/consul) that is created separately (and must be created first.)
The reason for the separate creation was to allow the EBS volumes to exist without the nodes, that may not be necessary
for restore or upgrade purposes.
