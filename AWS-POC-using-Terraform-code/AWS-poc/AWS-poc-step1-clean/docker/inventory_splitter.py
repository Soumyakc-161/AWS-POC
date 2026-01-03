import csv
import json
import os
import gzip
import boto3
from datetime import datetime

TMP_DIR = "/tmp"


def run_inventory_splitter():
    s3 = boto3.client("s3")

    # -------- ENV VARIABLES --------
    INVENTORY_BUCKET = os.environ["INVENTORY_BUCKET"]
    MANIFEST_KEY = os.environ["MANIFEST_KEY"]
    destination_bucket_name = os.environ["destination_bucket_name"]
    CHUNK_SIZE = int(os.environ.get("CHUNK_SIZE", "10000"))

  
    print("=== Inventory Splitter Started ===")

    print("INVENTORY_BUCKET:", INVENTORY_BUCKET)
    print("MANIFEST_KEY:", MANIFEST_KEY)
    print("destination_bucket_name:", destination_bucket_name)
    print("CHUNK_SIZE:", CHUNK_SIZE)

    # -------- DERIVED VALUES --------
    run_date = datetime.utcnow().strftime("%Y-%m-%d")
    CHUNK_PREFIX = f"inventory-chunks/run_date={run_date}/"
    print("CHUNK_PREFIX:", CHUNK_PREFIX)


    # -------- STEP 1: Download manifest.json --------
    manifest_path = f"{TMP_DIR}/manifest.json"

    print("Downloading manifest...")
    s3.download_file(INVENTORY_BUCKET, MANIFEST_KEY, manifest_path)

    with open(manifest_path) as f:
        manifest = json.load(f)

    # Inventory CSV.GZ path (usually only one)
    inventory_key = manifest["files"][0]["key"]
    print("Inventory file key:", inventory_key)


    gz_path = f"{TMP_DIR}/inventory.csv.gz"
    csv_path = f"{TMP_DIR}/inventory.csv"

    # -------- STEP 2: Download & unzip inventory --------
    print("Downloading inventory CSV.GZ...")
    s3.download_file(INVENTORY_BUCKET, inventory_key, gz_path)

    print("Unzipping inventory CSV.GZ...")
    with gzip.open(gz_path, "rt") as gz, open(csv_path, "w") as out:
        out.write(gz.read())

    # -------- STEP 3: Read CSV & split --------
    print("Splitting and uploading chunks...")
    with open(csv_path) as f:
        reader = csv.reader(f)
        header = next(reader)

        chunk_rows = []
        idx = 0

        for row in reader:
            chunk_rows.append(row)

            if len(chunk_rows) == CHUNK_SIZE:
                upload_chunk(
                    s3, header, chunk_rows, idx, destination_bucket_name, CHUNK_PREFIX
                )
                print(f"Uploaded chunk {idx} with {CHUNK_SIZE} chunk_rows")
                chunk_rows = []
                idx += 1

        if chunk_rows:
            upload_chunk(
                s3, header, chunk_rows, idx, destination_bucket_name, CHUNK_PREFIX
            )
            print(f"Uploaded final chunk {idx} with {len(chunk_rows)} chunk_rows")

    print("=== Inventory Splitter Finished Successfully ===")

def upload_chunk(s3, header, chunk_rows, idx, bucket, prefix):
    key = f"{prefix}inventory-part-{idx:06d}.csv"
    local_path = f"{TMP_DIR}/inventory-part-{idx:06d}.csv"

    with open(local_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writechunk_rows(chunk_rows)

    s3.upload_file(local_path, bucket, key)

if __name__ == "__main__":
    run_inventory_splitter()


