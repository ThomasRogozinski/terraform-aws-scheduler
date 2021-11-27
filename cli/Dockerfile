FROM python:3.9.7-slim-buster

WORKDIR /opt

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY ./scheduler_cli .

ENTRYPOINT [ "python3", "app.py" ]
