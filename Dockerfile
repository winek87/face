FROM python:slim AS builder

COPY Makefile /app/

RUN apt update -yq \
    && apt install -yq bzip2 cmake g++ make wget \
    && pip wheel -w /app/ dlib \
    && make -C /app/ download-models

FROM python:slim

COPY --from=builder /app/dlib*.whl /tmp/
COPY --from=builder /app/vendor/ /app/vendor/

RUN pip install flask numpy gunicorn \
    && pip install --no-index -f /tmp/ dlib \
    && rm /tmp/dlib*.whl

COPY facerecognition-external-model.py /app/
COPY gunicorn_config.py /app/

WORKDIR /app/

EXPOSE 5000

ARG GUNICORN_WORKERS="1" \
    PORT="5000"\
#    API_KEY="NZ9ciQuH0djnyyTcsDhNL7so6SVrR01znNnv0iXLrSk="
ENV GUNICORN_WORKERS="${GUNICORN_WORKERS}"\
    PORT="${PORT}"\
#    API_KEY="NZ9ciQuH0djnyyTcsDhNL7so6SVrR01znNnv0iXLrSk="\
    FLASK_APP=facerecognition-external-model.py

ENTRYPOINT ["gunicorn"  , "-c", "gunicorn_config.py", "facerecognition-external-model:app"]
