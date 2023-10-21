# Postgres Logical Replication

The goal here is to better understand how Postgres logical replication works, and provide a testbed for learning how best to configure logical replication. First, we set up Postgres logical replication running on Macbook localhost, publishing to an instance of Postgres running in a Docker container. We'll be using the [Postgres documentation](https://www.postgresql.org/docs/15/logical-replication.html). The subscribing database server will be running in a local Docker image, and we want to make sure we actually use the local image when we run the container.

![Architecture](/images/logical-replication-architecture.svg)

## Semi-automated setup

We're going to use a container named `subscriber1` for the entire exercise. The following procedure is a fast track, where many of the relevant commands are scripted:

1. open 3 iterms pointed to this directory.
1. ensure the relevant container is stopped `docker stop subscriber1`
1. run `./cleanup.sh` to remove previous docker cruft. Note: this nukes everything docker which isn't running.
1. run `./start.sh` to build and run the docker container with the second postgres database.
1. run `docker logs -f subscriber1` in one of the terminals
1. run `replication.sh` to configure the publisher running on localhost and subscriber running in a docker container.
1. log into the publisher database on localhost `psql -U postgres` -d publisher
1. log into the subscriber database on the container `PGPASSWORD=foobar psql -U postgres -p 5433 -h localhost`
1. log into localhost and insert `INSERT INTO books VALUES (4, 'four'), (5, 'five'), (6, 'six');`
1. check the subscriber values with `SELECT * FROM books;`

## Manual setup

The semi-automated procedure listed above could probably be fully automated into a single script, and in a production system that would be warranted. However, there is still value in  manually working through all the configuration steps, it provides a better understanding of how each step works, and provides opportunity to learn from any errors occurring during configuration. It proceeds as follows:

1. Prepare and operate a docker postgres instance.
2. Configure postgres localhost and docker instances for publish/subscribe.
3. Check the runtime to ensure it's operating correctly.

A running localhost instance of postgres on port 5432 is assumed.

### Preparing the Docker system

Skip this section if you're good with Docker and know how to use containers effectively on localhost.

Otherwise we're going to do a complete cleanup of the local Docker system to make it easier to build and debug the logical replication example.

General cleanup command, also in the `./cleanup.sh` script:
```docker system prune -af && \
    docker image prune -af && \
    docker system prune -af --volumes && \ # deletes build cache objects
    docker system df
```

Once that's done, the following should _not_ return any information:

1. `docker ps -a`
2. `docker container ls`
3. `docker images`-a

Now it's time to rebuild.

### Postgres on Docker

Three step procedure:

1. build the image from the Dockerfile
2. run the image to start the container
3. log in to the running container

Do the following:

- remove all previous postgres images and containers
    - `docker container rm <id>`
    - `docker image rm <id>`
    - build it: `docker buildx build . --tag subscriber1` which will produce an image.
    - run it: `docker run --name subscriber1 --rm -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d subscriber1` which will result in a running container as shown by `docker ps`
    - log in: `docker exec -it subscriber1 /bin/bash`
- docker buildx build .


I've managed to log into the docker container running on 5432. Now
to see if I can get logged in when it's running on 5433. Yep, that
works with the following:

THIS WILL NOT RUN THE LOCAL IMAGE UNLESS EVERYTHING IS CLEANED UP!

`docker run --name subscriber1 --rm -p 5433:5432 -e POSTGRES_PASSWORD=foobar -d subscriber1`

Consider always using the `--rm` flag to make it easier to rebuild and rerun containers.

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


### Publish/Subscribe

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

#### Publisher configuration

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

All of these are in the `pg_settings` table as name, setting.

There are two ways to configure, via settings file or using `ALTER SYSTEM`. Both methods require a databaser server restart.

##### Configuration file

Using a configuration file has the advantage of being able to diff changes in configuration files. This is almost always preferable, particularly when configuration files are under VC (which isn't a bad idea for anyone running their own cluster). However, the configuration file may not be available if the server is managed by a service provider.

Here's the diff:

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

##### ALTER SYSTEM

When the server is managed by a service provider, the configuration file may not be available or convenient, so the logical replication settings will need to be changed directly on the database server.

These can all be run with a `psql` command:
- `ALTER SYSTEM SET max_wal_senders TO 20;`
- `ALTER SYSTEM SET wal_level TO 'logical'; -- or 'replica', 'minimal', or 'archive' depending on desired level`
- `ALTER SYSTEM SET max_replication_slots TO <desired_value>;`

The database server will need to be restarted after any of the `ALTER SYSTEM` commands are executed. This works for my macbook:
- `pg_ctl -D /opt/homebrew/var/postgresql@14 restart`

These and any similar commands which configure the server run time need to be issued using an artifact which can be placed in version control. Ideally this would be a reversible migration script with up changing to the new values, and down restoring original values. This is fraught and easy to mess up. Care is warranted.


#### Subscriber configuration

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
`subscriber1`:
    - `docker exec -it subscriber1 /bin/bash`.

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
`docker build buildx . -t subscriber1`

Side note:
<pre>
postgres=# select version();
                                                              version
------------------------------------------------------------------------------------------------------------------------------------
 PostgreSQL 10.13 (Debian 10.13-1.pgdg90+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 6.3.0-18+deb9u1) 6.3.0 20170516, 64-bit
(1 row)
</pre>


#### Postgres configuration in Docker file

I put this project down years ago when I ran out of patience with the Docker `COPY` command for dealing with Postgres configuration files. This blog post on [How to modify postgresql config file running inside docker](https://devniklesh.medium.com/how-to-modify-postgresql-config-file-running-inside-docker-e06fe4f7a072) shows another way to do it. I don't think it's the best way to do it, but if I can get it to work, I can figure out something better later.

```
postgres=# SHOW config_file;
               config_file
------------------------------------------
 /var/lib/postgresql/data/postgresql.conf
(1 row)

postgres=#
```

### Debugging

Some useful commands:

- MAKE SURE TO RUN THE DOCKER IMAGE WHICH WAS BUILT LOCALLY.
- `docker logs -f subscriber1` for subscriber logs
-  ensure the postgres versions are compatible; consider running the same versions of postgres for both publisher and subscriber
- On the published, check the replication table: `select * from pg_stat_replication;`
- Check the subscription on the publisher with `select * from pg_stat_replication;`

## Demo data using Goodreads CSV export

[Exporting from Goodreads](https://www.goodreads.com/review/import) is straightforward. The resulting CSV file is easy to read into Ruby using `irb`:

 ```
$ irb
3.2.2 :001 > require 'csv'
 => true
3.2.2 :002 > csv = CSV.read('goodreads_export-2023-10-17.csv', headers: true)
 =>
#<CSV::Table mode:col_or_row row_count:154>
...
3.2.2 :003 >
```

The schema was extracted using the `csvsql` command from the `csvkit` tools.