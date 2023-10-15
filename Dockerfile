FROM postgres:14
# USER postgres

RUN echo "building postgres 14"
COPY ./foo.txt /quux.txt
# COPY --chown=postgres:postgres ./postgresql.conf.test /var/lib/postgresql/data/
# COPY postgresql.conf.test /var/lib/postgresql/data/
# COPY ./foo.txt /var/lib/postgresql/data/quux.txt
# COPY ./foo.txt /var/lib/postgresql/quux.txt
# RUN echo $?

# https://stackoverflow.com/questions/30848670/how-to-customize-the-configuration-file-of-the-official-postgresql-docker-image

# TODO: copy the postgresql.conf file from the working subscriber and update
# this file to ensure the subscriber is configured correctly with the correct
# version of postgresql configuration.
COPY postgresql.conf      /etc/postgresql/postgresql.conf

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
