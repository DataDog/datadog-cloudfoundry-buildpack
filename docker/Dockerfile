FROM debian:9

# Be sure to set the datadog directory
# This is used in the dd app scripts
ENV DATADOG_DIR /datadog

# This is a setting for a simple flask app
ENV FLASK_APP /app/app.py
ENV DATADOG_ENV cloudfoundry_docker_example

# install python and pip, then clean up what's left over
# python is required by the buildpack and the app
RUN apt-get update && apt-get install -y python python-pip \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/tmp/*

# Copy the datadog binaries and scripts into the image
COPY ./lib /datadog

COPY ./docker/app/requirements.txt /app/requirements.txt

# Install the python requirements
RUN pip install -r /app/requirements.txt

COPY ./docker/app/app.py /app/app.py

# Copy the entrypoint and the flask app
COPY ./docker/entrypoint.sh entrypoint.sh

ENTRYPOINT ["bash", "/entrypoint.sh"]

CMD ["ddtrace-run", "python", "/app/app.py"]
