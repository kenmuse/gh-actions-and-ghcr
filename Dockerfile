FROM python:3

LABEL org.opencontainers.image.description="Sample application demonstrating the use of the GitHub Container Registry"

WORKDIR /src
COPY ./src /src

RUN pip install -r requirements.txt

EXPOSE 80
ENTRYPOINT FLASK_APP=/src/app.py flask run --host=0.0.0.0 --port=80