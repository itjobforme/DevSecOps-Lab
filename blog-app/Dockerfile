FROM python:3.9

WORKDIR /app


COPY app.py /app/
COPY admin.py /app/
COPY models.py /app/
COPY requirements.txt /app/
COPY templates /app/templates

RUN pip install -r requirements.txt

EXPOSE 80

CMD ["python", "app.py"]
