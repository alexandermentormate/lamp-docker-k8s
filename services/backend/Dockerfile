FROM python:3.10-alpine3.15

ENV GROUP_ID=1000 \
    USER_ID=1000

WORKDIR /app

COPY requirements.txt .

RUN pip install -r requirements.txt
RUN apk update; apk add curl

COPY . .

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=30s --start-period=30s --retries=5 \
            CMD curl -f http://localhost:5000/health || exit 1

CMD [ "gunicorn", "-w", "4", "--bind", "0.0.0.0:5000", "--chdir", "/app", "wsgi", "--log-level", "debug"]
