FROM postgres:latest
# USER postgres

RUN echo "foobar"
COPY ./foo.txt /quux.txt
# COPY --chown=postgres:postgres ./postgresql.conf.test /var/lib/postgresql/data/
# COPY postgresql.conf.test /var/lib/postgresql/data/
# COPY ./foo.txt /var/lib/postgresql/data/quux.txt
# COPY ./foo.txt /var/lib/postgresql/quux.txt
# RUN echo $?

# https://stackoverflow.com/questions/30848670/how-to-customize-the-configuration-file-of-the-official-postgresql-docker-image

# COPY postgresql.conf      /tmp/postgresql.conf
COPY postgresql.conf      /etc/postgresql/postgresql.conf
# COPY updateConfig.sh      /docker-entrypoint-initdb.d/_updateConfig.sh

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
