# tf-gcp-infra

## Introduction
IaaC Terraform GCP Infrastructure.

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