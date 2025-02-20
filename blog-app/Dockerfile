FROM python:3.9-slim

WORKDIR /app
COPY app.py /app/
COPY requirements.txt /app/
COPY templates/ /app/templates/ 

RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "app.py"]


