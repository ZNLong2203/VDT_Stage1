FROM apache/superset:latest

USER root

RUN pip install --no-cache-dir "trino[sqlalchemy]"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER superset

ENTRYPOINT ["/entrypoint.sh"]
CMD ["superset", "run", "-p", "8088", "--with-threads", "--reload", "--debugger"]
