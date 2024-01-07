FROM postgres:16
# USER postgres

RUN echo "building postgres 16"
# COPY --chown=postgres:postgres ./postgresql.conf.test /var/lib/postgresql/data/
# COPY postgresql.conf.test /var/lib/postgresql/data/
# COPY ./foo.txt /var/lib/postgresql/data/quux.txt
# COPY ./foo.txt /var/lib/postgresql/quux.txt
# RUN echo $?

# https://stackoverflow.com/questions/30848670/how-to-customize-the-configuration-file-of-the-official-postgresql-docker-image

# Copy the postgresql.conf file from the working subscriber and update
# this file to ensure the subscriber is configured correctly with the correct
# version of postgresql configuration.
# If this file isn't copied, the configuration will have to be done manually,
# and the container restarted.
# COPY postgresql.conf      /etc/postgresql/postgresql.conf

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      netcat-openbsd iputils-ping curl less tcpdump nmap iperf net-tools \
      traceroute nmap tcpdump iperf && \
    rm -rf /var/lib/apt/lists/*

CMD ["postgres"] # , "-c", "config_file=/etc/postgresql/postgresql.conf"]
