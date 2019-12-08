# Setup Utility Cluster
This cluster contains a set of services to provide the following capabilities in AWS:

  * Monitor capture service (Prometheus)
  * Dashboard and graphing of monitored data (Grafana)
  * Alert management (AlertManager)
  * Service Discovery and Configuration Management (Consul)

These services are setup using Terraform and Ansible. The VPC is assumed to be already setup as is the key
to access the nodes. Linux service accounts are created for each of the services.

An nginx proxy is setup to allow the services to communicate via the private ips.


