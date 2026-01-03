import os
import csv
import boto3
import pyarrow as pa
import pyarrow.parquet as pq
#from datetime import datetime
#from urllib.parse import unquote


TMP_DIR = "/tmp"

def run_chunk_processor():
    s3 = boto3.client("s3")

    source_bucket_name = os.environ["source_bucket_name"]
    destination_bucket_name   = os.environ["destination_bucket_name"]
    RUN_DATE      = os.environ["RUN_DATE"]


    index = int(os.environ.get("AWS_BATCH_JOB_ARRAY_INDEX"))

    chunk_key = (
        f"inventory-chunks/run_date={RUN_DATE}/"
        f"inventory-part-{index:06d}.csv"
    )
    print(f"=== Processing chunk index {index} ===")
    print("Processing chunk:", chunk_key)

    local_chunk = f"{TMP_DIR}/chunk.csv"
    s3.download_file(destination_bucket_name, chunk_key, local_chunk)

    records = []
    
 # ---------- READ CHUNK CSV ----------
    with open(local_chunk, newline='') as f:
        reader = csv.reader(f)
        header = next(reader)

        for row in reader:
            bucket = row[0]
            key = row[1]
            size = int(row[2])

            #key = unquote(key)


            #obj = s3.get_object(Bucket=source_bucket_name, Key=key)
            #body = obj["Body"].read().decode()

            records.append({
                "key": key,
                "size": size,
                "file_extension": key.split('.')[-1].lower(),
                "raw_payload": "sample"  # sample
            })
            if not records:
                print("No records found in chunk, exiting cleanly")
                return

    table = pa.Table.from_pylist(records)

    parquet_path = f"{TMP_DIR}/chunk-{index:06d}.parquet"
    pq.write_table(table, parquet_path, compression="SNAPPY")


    output_key = (
        f"processed/run_date={RUN_DATE}/"
        f"part-{index:06d}.parquet"
    )

    s3.upload_file(parquet_path, destination_bucket_name, output_key)

    print("Wrote output:", output_key)
    print("=== Chunk Processor Finished Successfully ===")

if __name__ == "__main__":
    run_chunk_processor()
