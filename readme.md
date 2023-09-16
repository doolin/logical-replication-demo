# Postgres Logical Replication

The goal here is to set up logical replication running on localhost, _viz._ a Macbook.
We'll be using the [Postgres documentation](https://www.postgresql.org/docs/15/logical-replication.html).

## Postgres on Docker

I've managed to log into the docker container running on 5432. Now
to see if I can get logged in when it's running on 5433. Yep, that
works with the following:

`docker run --name docker-post -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d postgres`

This is what it looks like when running immediately after a clean install:

<pre class="brash:Bash">
09:01:39 doolin@hinge:~  ruby-2.6.3
$ psql -U postgres -p 5433 -h localhost
Password for user postgres:
psql (14.9)
Type "help" for help.

postgres=# \l
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(3 rows)

postgres=#
</pre>


## Publish/Subscribe

The next thing which needs to happen is configuring both the publisher and subscriber.
The following will minimize the amount of configuration, as the localhost configuration is
very easy to persistently modify, leaving the epheremal configuration limited to
the docker postgres instance:

- **Publisher**: the brew-managed localhost instance. Configure once.
- **Subscriber**: the instance running in the docker container. Configure via docker.
- Configuring in the Docker container is going to be a bit tricky. The configuration details for Postgres are [Chapter 31 Logical Replication](https://www.postgresql.org/docs/12/logical-replication.html). Getting the Docker file configured will be some work on stack overflow.

With a brew install, keep track of local changes is always a real hassle. What I should do
is create a backup file, make the modifications, then store the diff between the two
files.

### Publisher configuration

For the [publisher
configuration](https://www.postgresql.org/docs/15/logical-replication-config.html):

> On the publisher side, `wal_level` must be set to logical, and
> `max_replication_slots` must be set to at least the number of subscriptions
> expected to connect, plus some reserve for table synchronization. And
> `max_wal_senders` should be set to at least the same as `max_replication_slots`
> plus the number of physical replicas that are connected at the same time.

* `wal_level = logical`
* `max_replication_slots = 10`
* `max_wal_senders = 15`

Here's the diff

<pre>
193c193
< wal_level = logical			# minimal, replica, or logical
---
> #wal_level = replica			# minimal, replica, or logical
286c286
< max_wal_senders = 15		# max number of walsender processes
---
> #max_wal_senders = 10		# max number of walsender processes
291c291
< max_replication_slots = 10	# max number of replication slots
---
> #max_replication_slots = 10	# max number of replication slots
</pre>

Now the server needs to be restarted, either will work with a `brew` installation:

- `brew services restart postgresql@14`
- `pg_ctl -D /opt/homebrew/var/postgresql@14 restart`

Ensure works by logging in with `psql -U postgres` and running the query
`select * from pg_file_settings;` to see the values which were set in the
configuration file.


### Subscriber configuration

We'll try and get the [subscriber
configuration](https://www.postgresql.org/docs/12/logical-replication-config.html)
working before attempting to `CREATE PUBLISHER`, etc.

Here's the relevant text:

> The subscriber also requires the `max_replication_slots` to be set. In this
> case it should be set to at least the number of subscriptions that will be
> added to the subscriber. `max_logical_replication_workers` must be set to at
> least the number of subscriptions, again plus some reserve for the table
> synchronization. Additionally the `max_worker_processes` may need to be adjusted
> to accommodate for replication workers, at least
> (`max_logical_replication_workers + 1`). Note that some extensions and parallel
> queries also take worker slots from max_worker_processes.

Some steps:

1. Log into current postgres docker container and examine the
appropriate values in the configuration file. For a container named
`docker-post`, `docker exec -it docker-post /bin/bash`.

2. We need to create a local Dockerfile, acquire the postgresql.conf
which is compatible, configure that correctly, then copy the conf file
into the container. In the container, we have `/var/lib/postgresql/data/postgresql.conf`.

3. `docker cp docker-post-10:/var/lib/postgresql/data/postgresql.conf /host/path/target`
In this case, I'm making target `.`.

4. Set the following in the subscriber configuration:
  * `max_replication_slots`
  * `max_logical_replication_workers`
  * `max_worker_processes`

5. After adding material to Dockerfile, need to build it:
`docker build -t localpost:13 .`

Side note:
<pre>
postgres=# select version();
                                                              version
------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 10.13 (Debian 10.13-1.pgdg90+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 6.3.0-18+deb9u1) 6.3.0 20170516, 64-bit
(1 row)
</pre>


### Postgres configuration in Docker file

I put this project down years ago when I ran out of patience with the Docker `COPY` command for dealing with Postgres configuration files. This blog post on [How to modify postgresql config file running inside docker](https://devniklesh.medium.com/how-to-modify-postgresql-config-file-running-inside-docker-e06fe4f7a072) shows another way to do it. I don't think it's the best way to do it, but if I can get it to work, I can figure out something better later.

```
postgres=# SHOW config_file;
               config_file
------------------------------------------
 /var/lib/postgresql/data/postgresql.conf
(1 row)

postgres=#
```
