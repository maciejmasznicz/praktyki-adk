FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY adk ./adk

ENV PYTHONUNBUFFERED=1
ENV PORT=8080

CMD ["adk", "api_server", "--with_ui", "--host", "0.0.0.0", "--port", "8080", "--session_service_uri=memory://", "--artifact_service_uri=memory://", "./adk"]