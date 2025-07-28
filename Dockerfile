FROM --platform=linux/amd64 python:3.10

WORKDIR /app

COPY requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

COPY parsing.py /app/parsing.py

CMD ["python3", "parsing.py"]
