FROM python:3.13-slim
RUN pip install --no-cache-dir pglast==7.22
WORKDIR /workspace
ENTRYPOINT ["python", "/workspace/scripts/sqlcheck/check_sql.py"]
