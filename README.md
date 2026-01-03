<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/3ddc0bc0-04eb-4916-8a2b-612e21768288" />

# 📘 AWS POC – S3 Inventory → AWS Batch → Parquet Pipeline (Terraform)

## 📌 Project Overview

This project demonstrates a **real-world AWS data engineering pipeline** built using **Terraform (Infrastructure as Code)**.

The pipeline processes **Amazon S3 Inventory metadata** using **AWS Batch (Fargate)** and converts it into **Parquet files** that are ready for analytics tools like **Databricks** or **Amazon Athena**.

## 🎯 What This POC Solves

* Large S3 buckets can contain **millions of objects**
* Reading them directly is slow and expensive
* S3 Inventory provides metadata efficiently
* AWS Batch enables **parallel processing at scale**
* Parquet format enables **fast analytics**

---

## 🧱 High-Level Architecture

```
Source S3 Bucket
│
├── Daily S3 Inventory (CSV metadata)
│
├── AWS Batch – Inventory Splitter (Single Job)
│       └── inventory-chunks/*.csv
│
├── AWS Batch – Chunk Processor (Array Job)
│       └── processed/*.parquet
│
└── Analytics Layer (Databricks / Athena)
```

---

## 🛠 AWS Services Used

* Amazon S3
* S3 Inventory
* AWS Batch (Fargate)
* Amazon ECR
* AWS IAM
* Docker
* Terraform

---

## 📂 Repository Structure

```
AWS-POC-USING-TERRAFORM-CODE/
└── AWS-poc/
└── AWS-poc-step1-clean/
├── docker/
│   ├── inventory_splitter.py
│   ├── chunk_processor.py
│   ├── Dockerfile
│   └── main.py
├── batch.tf
├── ecr_step3.tf
├── iam.tf
├── job_definitions.tf
├── providers.tf
├── s3_inventory.tf
├── source.tf
├── variables.tf
├── terraform.tfvars
└── README.md
```

⚠️ **Do NOT commit**

* `.terraform/`
* `terraform.tfstate*`

---

# 🧩 Step-by-Step Pipeline Explanation

---

## ✅ STEP 1: Create Source & Destination S3 Buckets

### 🔹 What we do

* Use Terraform to:

  * Create a **new source bucket**
  * Create a **new destination bucket**

### 🔹 Why this step is needed

* Source bucket contains **actual data objects**
* Destination bucket stores:

  * Inventory metadata
  * Chunk files
  * Final Parquet output

### 🔹 Terraform files involved

* `source.tf`
* `variables.tf`
* `terraform.tfvars`

### 🔹 What happens internally

* Terraform checks AWS state
* Creates destination bucket if it doesn’t exist
* No data is copied at this stage

### 🔹 Output

* Two S3 buckets available

📸 **Screenshot to add here**



* AWS S3 Console → Bucket list showing both buckets

---

## ✅ STEP 2: Enable S3 Inventory on Source Bucket

### 🔹 What we do

* Enable **daily S3 Inventory**
* Inventory is delivered as **CSV files**
* Output bucket = destination bucket

### 🔹 Why this step is needed

* Listing millions of objects manually is expensive
* S3 Inventory provides:

  * Scalable
  * Cost-efficient
  * Consistent metadata snapshots

### 🔹 Terraform file involved

* `s3_inventory.tf`
<img width="1546" height="338" alt="image" src="https://github.com/user-attachments/assets/4ef03151-d97a-432b-ae9d-8b8697108be6" />

### 🔹 What happens internally

1. AWS generates inventory once per day
2. Metadata is written as compressed CSV
3. Files are automatically stored in S3

### 🔹 What data is included

* Object key (path)
* Size
* Last modified timestamp
* Storage class

🚫 **Not included**

* File content
* Parquet data itself

### 🔹 Output

```
s3://<destination-bucket>/inventory/
└── YYYY-MM-DD/
    └── inventory.csv.gz
```

📸 **Screenshot to add here**

* S3 → Inventory configuration
* Inventory CSV file in destination bucket
<img width="1902" height="803" alt="image" src="https://github.com/user-attachments/assets/fa3ef4bd-a70f-4344-ae39-7ab882bec384" />

---

## ✅ STEP 3: Inventory Splitter (AWS Batch – Single Job)

### 🔹 What we do

* Run **one AWS Batch job**
* Download inventory CSV
* Split it into smaller chunk files

### 🔹 Why this step is needed

* Inventory CSV can be **very large**
* Parallel processing requires smaller inputs
* Each chunk = independent processing unit

### 🔹 Code used

* `docker/inventory_splitter.py`

### 🔹 Terraform involved

* `batch.tf`
* `job_definitions.tf`
* `iam.tf`

### 🔹 What happens internally

1. Batch pulls Docker image from ECR
2. Script downloads inventory CSV
3. Reads records in memory
4. Splits data into N chunks
5. Uploads chunk files to S3

### 🔹 Output

```
s3://<destination-bucket>/inventory-chunks/
└── run_date=YYYY-MM-DD/
    ├── inventory-part-000000.csv
    ├── inventory-part-000001.csv
    └── ...
```

📸 **Screenshot to add here**

* AWS Batch job → SUCCEEDED
* inventory-chunks folder in S3
<img width="1919" height="775" alt="image" src="https://github.com/user-attachments/assets/deebfc3b-bf4b-4fb6-89e3-c6efa85fb7d0" />

---

## ✅ STEP 4: Chunk Processor (AWS Batch – Array Job)

### 🔹 What we do

* Launch an **AWS Batch array job**
* Each container processes **one chunk**

### 🔹 Why this step is needed

* Enables **parallel processing**
* Scales automatically
* Faster processing for large inventories

### 🔹 Code used

* `docker/chunk_processor.py`

### 🔹 How array jobs work

* AWS sets `AWS_BATCH_JOB_ARRAY_INDEX`
* Index maps to a specific chunk file

### 🔹 What happens internally

1. Batch launches multiple containers
2. Each container:

   * Reads its chunk CSV
   * Converts rows to Parquet
   * Uploads output to S3

### 🔹 Output

```
s3://<destination-bucket>/processed/
└── run_date=YYYY-MM-DD/
    ├── part-000000.parquet
    ├── part-000001.parquet
    └── ...
```

📸 **Screenshot to add here**

* Batch array job showing multiple child jobs
* processed/ folder with parquet files
<img width="1919" height="835" alt="image" src="https://github.com/user-attachments/assets/95b87ab7-5a5e-4f83-9390-ec9bdad9fe81" />

---

## ✅ STEP 5: Docker Image

### 🔹 What we do

* Build **one Docker image**
* Contains both Python scripts

### 🔹 Why this design

* Reusable image
* Different behavior via command override
* Simplifies deployment

### 🔹 Files involved

* `docker/Dockerfile`
* `inventory_splitter.py`
* `chunk_processor.py`

📸 **Screenshot to add here**

* Docker build logs (optional)
<img width="1588" height="120" alt="image" src="https://github.com/user-attachments/assets/ed3b718d-92b5-4d4d-b96c-5d1c52ffe64a" />

---

## ✅ STEP 6: Amazon ECR

### 🔹 What we do

* Create ECR repository
* Push Docker image

### 🔹 Terraform file

* `ecr_step3.tf`

### 🔹 What happens internally

* Image is stored securely
* Batch pulls image at runtime

📸 **Screenshot to add here**

* ECR repository with image tag
<img width="1913" height="429" alt="image" src="https://github.com/user-attachments/assets/a0ff3caa-7c71-484d-b68d-5d491fd31353" />

---

## ✅ STEP 7: AWS Batch Core Infrastructure

### 🔹 Components created

* Compute Environment (Fargate)
* Job Queue
* Job Definitions
* IAM Roles

### 🔹 Why AWS Batch

* Handles retries
* Scales automatically
* Suitable for large batch workloads

📸 **Screenshot to add here**

* Batch compute environment
  <img width="1916" height="827" alt="image" src="https://github.com/user-attachments/assets/be0194d1-1dc5-4041-b1b1-3701fb2f56db" />

* Job queue
  <img width="1902" height="765" alt="image" src="https://github.com/user-attachments/assets/af711564-5b76-47b4-bf31-d74a93303b69" />

* Job definitions
<img width="1919" height="638" alt="image" src="https://github.com/user-attachments/assets/ef5a5f33-1174-4ee6-b183-aef736466c53" />
<img width="1900" height="688" alt="image" src="https://github.com/user-attachments/assets/71c4ee7e-28af-4e27-8b6b-8267779a94e8" />

---

## ✅ STEP 8: Final Parquet Output

### 🔹 What we achieve

* Analytics-ready Parquet files
* Optimized for columnar queries

### 🔹 Why Parquet

* Compression
* Faster scans
* Lower cost

📸 **Screenshot to add here**

* Athena / Databricks reading parquet (optional)
<img width="1919" height="835" alt="Screenshot 2026-01-03 232447" src="https://github.com/user-attachments/assets/7282cdb9-2dc7-46a5-a32a-15d6e9499a5a" />

---

## 🔐 IAM & Security Model

* **Execution Role**

  * Pull image
  * Write logs

* **Job Role**

  * Read/write S3

* **Batch Service Role**

  * Managed by AWS

📌 **Compute environment has no direct permissions**

---

## 🚀 How to Deploy

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

---

## 🧠 Key Learnings

* Terraform best practices
* AWS Batch with Fargate
* S3 Inventory processing
* Parallel data pipelines
* Secure IAM design

---

## 📌 Future Enhancements

* Cross-account S3 access via VPC endpoint
* Glue Data Catalog
* CloudWatch alarms
* Databricks Autoloader

---

