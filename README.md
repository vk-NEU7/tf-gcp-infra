# tf-gcp-infra

## Introduction
IaaC Terraform GCP Infrastructure.

The presented Terraform configuration defines an intricate infrastructure deployment on Google Cloud Platform (GCP), covering a wide array of essential components. It orchestrates the setup of a Virtual Private Cloud (VPC), including subnetworks and firewall rules, ensuring network isolation and security. Compute resources such as instances, instance groups, and autoscalers are provisioned to handle application workloads efficiently, with integrated health checks and load balancing for high availability. Additionally, the configuration automates the deployment of SQL databases(Postgresql) and associated instances, complete with encryption key management for enhanced security. Pub/Sub messaging infrastructure is established, enabling reliable communication between services, while Cloud Storage buckets are configured to handle data storage needs, with encryption and access control enforced through IAM bindings. The setup is complemented by load balancers with SSL termination, facilitating secure and scalable access to applications. By leveraging Terraform's modular approach, the infrastructure is not only robust and scalable but also easily customizable and maintainable, ensuring seamless management and adaptability to evolving requirements. The accompanying README provides comprehensive guidance on deployment, customization, and ongoing maintenance, empowering users to efficiently manage their GCP environments with confidence and ease.

## Prerequisites.
- [Terraform](https://www.terraform.io/) installed on your machine
- [GCP CLI](https://cloud.google.com/sdk/gcloud) installed on your machine

## Setup Instructions
Instructions for setting up the infrastructure using Terraform.

1. **Clone the Repository:**
    ```bash
    git clone https://github.com/cloudapp6225/tf-gcp-infra.git

    cd tf-gcp-infra
    ```

2. **Enable google cloud compute engine API**
   ```bash
    $ gcloud services enable compute.googleapis.com
    $ gcloud services enable servicenetworking.googleapis.com --project=dev-gcp-project-1
    $ gcloud services enable oslogin.googleapis.com
    $ gcloud services enable artifactregistry.googleapis.com
    $ gcloud services enable certificate.googleapis.com
    $ gcloud services enable cloudbuild.googleapis.com
    $ gcloud services enable deploymentmanager.googleapis.com
    $ gcloud services enable dns.googleapis.com
    $ gcloud services enable cloudfunctions.googleapis.com
    $ gcloud services enable cloudkms.googleapis.com
    $ gcloud services enable logging.googleapis.com
    $ gcloud services enable monitoring.googleapis.com
    $ gcloud services enable pubsub.googleapis.com
    $ gcloud services enable run.googleapis.com
    $ gcloud services enable sqladmin.googleapis.com
    $ gcloud services enable storage-component.googleapis.com
    $ gcloud services enable networkconnectivity.googleapis.com
    $ gcloud services enable vpcaccess.googleapis.com
    $ gcloud services enable serviceusage.googleapis.com

    ```

3. **Initialize Terraform:**
    ```bash
    terraform init
    ```

4. **Terraform Configuration:**
    Review the `main.tf`, `terraform.tfvars`. Modify variables in `terraform.tfvars` as needed for your environment.

5. **Plan Infrastructure Changes:**
    ```bash
    terraform plan
    ```

6. **Apply Infrastructure Changes:**
    ```bash
    terraform apply
    ```

7. **Verify the Infrastructure:**
    After Terraform applies the changes successfully, verify the infrastructure on GCP.

## Cleaning Up
Instructions for tearing down the infrastructure

1. **Destroy Infrastructure:**
    ```bash
    terraform destroy
    ```

2. **Confirm Destruction:**
    Terraform will prompt you to confirm destruction. Enter `yes` to proceed with tearing down the infrastructure.
