FROM python:3.9-slim

RUN pip install kafka-python

COPY producer.py /app/producer.py

WORKDIR /app

ENTRYPOINT ["python", "producer.py"]
