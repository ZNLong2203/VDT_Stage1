FROM flink:1.17

USER root

RUN apt-get update && \
    apt-get install -y python3 python3-pip wget && \
    ln -s /usr/bin/python3 /usr/bin/python

RUN pip3 install --prefer-binary apache-flink==1.17

COPY ../jars/flink-sql-connector-postgres-cdc-3.1.1.jar /opt/flink/lib/
COPY ../jars/mysql-connector-java-8.0.30.jar /opt/flink/lib/
COPY ../jars/flink-connector-jdbc-3.1.1-1.17.jar /opt/flink/lib/
COPY ../jars/flink-connector-starrocks-1.2.9_flink-1.17.jar /opt/flink/lib/
COPY ../jars/flink-cdc-pipeline-connector-starrocks-3.1.1.jar /opt/flink/lib/

WORKDIR /opt/pyflink-job

CMD ["python3", "main.py"]
