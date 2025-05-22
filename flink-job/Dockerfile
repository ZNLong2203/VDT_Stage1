FROM flink:1.17-scala_2.12-java11

USER root

RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir kafka-python

WORKDIR /app

COPY app.py .

CMD ["python3", "app.py"]
