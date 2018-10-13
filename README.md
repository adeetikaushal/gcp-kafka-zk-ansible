# Introduction

Ansible provides a simple way to deploy, manage, and configure the Apache KAfka. 

* Installs Apache Kafka Platform packages
* Starts services using systemd scripts


The services that can be installed from this repository are:

* ZooKeeper
* Kafka


# Scope

These Ansible playbooks are intended as a general template for setting up a production-ready proof of concept environment. There are three available templates.

* PLAINTEXT -- use these templates if you have no requirements for a secured environment


# Running 

Update the roles/gcp/tasks/main.yml with credentials
Update the roles/kafka/default/main.yml with download url
Update the roles/zookeeper/default/main.yml with download url


 * GCP with only instances
 
    Create new instances
      ./install.sh <projname> <No of Kafka nodes> true
 
    Use existing instances
    ./install.sh <projname> <No of Kafka nodes> false
 
 
  * GCP with  instances-groups
 
     Create new instances
     ./install-grp.sh <projname> <No of Kafka nodes> true
 
     Use existing instances
     ./install-grp.sh <projname> <No of Kafka nodes> false
 
 
   * Only ansible : update hosts.yml with IPS

       ansible-playbook -i hosts.yml all.yml