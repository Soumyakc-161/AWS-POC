FROM python:3.10-slim

#RUN pip install boto3 
RUN pip install boto3 pyarrow 

WORKDIR /app

COPY inventory_splitter.py .
COPY chunk_processor.py .

CMD ["sleep", "infinity"]
