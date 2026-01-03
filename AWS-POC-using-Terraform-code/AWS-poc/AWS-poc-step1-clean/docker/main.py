#main.py                 # ENTRY POINT (decides behavior)

import os
import sys

JOB_TYPE = os.environ.get("JOB_TYPE")

if JOB_TYPE == "inventory_splitter":
    from inventory_splitter import run_inventory_splitter
    run_inventory_splitter()

elif JOB_TYPE == "chunk_processor":
    from Chunk_Processor import run_chunk_processor
    run_chunk_processor()

else:
    print("ERROR: JOB_TYPE must be 'inventory_splitter' or 'chunk_processor'")
    sys.exit(1)
