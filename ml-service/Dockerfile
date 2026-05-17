FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8001

CMD ["sh", "-c", "python -m uvicorn app.main:app --host ${APP_HOST:-0.0.0.0} --port ${APP_PORT:-8001}"]
