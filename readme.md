# Postgres Logical Replication

The goal here is to better understand how Postgres logical replication works, and provide a testbed for learning how best to configure logical replication. First, we set up Postgres logical replication running on Macbook localhost, publishing to an instance of Postgres running in a Docker container. We'll be using the [Postgres documentation](https://www.postgresql.org/docs/15/logical-replication.html). The subscribing database server will be running in a local Docker image, and we want to make sure we actually use the local image when we run the container.

![Architecture](/images/logical-replication-architecture.svg)

---

## Grafana

For a first build or a complete rebuild, run `./cleanup.sh` and remove all of the images. This does not remove volumes.

Then:
- `docker volume rm grafana-storage`
- `./restart.sh`
- `./replication.sh`

Hooks up to InfluxDB. Here's the process:

1. connections --> Data sources --> InfluxDB
1. Set **Query language** to `Flux`.
1. URL: `http://pubmetrics:8086`
1. Organization: `inventium`
1. Token: paste in the token from Influx.

Run these to provision some data into influx:

- `./pgbench.sh`
- `./exe/pg_sampler.rb`
`
Once Influx is running, the Flux query in Influx can be copied to a Grafana dashboard and used as-is. Here is one which works:

```from(bucket: "ruby_test")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "locks")
  |> filter(fn: (r) => r["_field"] == "lock_count")
  |> filter(fn: (r) => r["mode"] == "AccessShareLock" or r["mode"] == "ExclusiveLock" or r["mode"] == "RowExclusiveLock" or r["mode"] == "ShareLock" or r["mode"] == "ShareUpdateExclusiveLock")
  ```

**Note** make sure the influxDB token is correct.

Once a dashboard is saved, the autorefresh can be set.

---

**2023-11-22**

Do the following steps to replicate set up for benchmarking:

1. `./restart.sh`
1. `./replication.sh`
1. `./test.sh`
1. `./exe/pg_sampler.rb`
1. `./pgbench.sh`
1. Watch the stats in the docker desktop tool.
1. [Log into influx and check the data](http://localhost:8086/orgs/61386260b136e3c2/data-explorer?fluxScriptEditor)
1. [Log into grafana and check the data](http://localhost:3000/d/ee3f1dd1-31ef-4efa-a26a-a9d30fd6ebb0/testem-dashboard?orgId=1&viewPanel=1&editPanel=1)



**2023-11-10**

Here's a list of things on my mind. I don't have time to do them right now, or even
plan them out in detail, but having them written out explicitly is helpful.

- The overall point of the exercise is to run Rails queries and watch what happens in the entire system, particularly the database, and how the behavior propogates through the metrics.
- Will need to generate some fairly burly synthetic data to be able to stress the system.


**2023-11-04**

- `./restart.sh`
- `./replication.sh`
- `./test.sh`
- `./exe/books_inserter.rb`
- Watch the stats in the docker desktop tool.
- `./exe/insert_db_client`
- [Log into influx and check the data](http://localhost:8086/orgs/61386260b136e3c2/data-explorer?fluxScriptEditor)
- [Log into grafana and check the data](http://localhost:3000/d/ee3f1dd1-31ef-4efa-a26a-a9d30fd6ebb0/testem-dashboard?orgId=1&viewPanel=1&editPanel=1)

TODO:

1. Rewrite this whole document.
2. Have one section for a completely manual procedure for one pub/sub.
3. Have a another section for full automated two pub/subs.
4. Describe the makefile and scripts.

## Semi-manual pub/sub

The idea here is to build the system stepwise in order to help learn how everything works.


## Semi-automated setup

We're going to use an image named `subscriber` with containers named `subscriber1` and `subscriber2` for the entire exercise. The following procedure is a fast track, where many of the relevant commands are scripted:

1. open 3 iterms pointed to this directory. If you have `tmux` installed, the commands below are scripted to open a session logging both subscriber containers.
1. ensure the relevant container is stopped `docker stop subscriber1`
1. run `./cleanup.sh` to remove previous docker cruft. Note: this nukes everything docker which isn't running.
1. run `./start.sh` to build and run the docker container with the second postgres database.
1. run `docker logs -f subscriber1` in one of the terminals
1. run `replication.sh` to configure the publisher running on localhost and subscriber running in a docker container.
1. log into the publisher database on localhost `psql -U postgres` -d publisher
1. log into the subscriber database on the container `PGPASSWORD=foobar psql -U postgres -p 5433 -h localhost`
1. log into localhost and insert `INSERT INTO books VALUES (4, 'four'), (5, 'five'), (6, 'six');`
1. check the subscriber values with `SELECT * FROM books;`

## Working with schema changes

Schema changes for logical replication are fraught. Technically they aren't very difficult, but the people side of managing a number of engineers who ship a lot of Rails schema migrations on a regular basis is going to be difficult. The best bet would be changing the habit of reaching for a migration for everything, to stop treating the database as a giant global struct. Failing that, schema changes as expressed by Rails migrations would need to be slowed down to ensure schema replication occurred.

In general, schema changes on the publisher are not replicated on subscribers. Unless certain conditions are met, schema changes will need to be run on both publisher and subscribers, and the replication state will likely need to be managed while the state is changed. At the time of writing, small scripts are being developed as a sort of dsl for managing state and configuration for the containers and databases.


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
3. `docker images -a``

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
- Check the environment variables in the container:
    ```
    docker exec -it telegraf /bin/sh
    echo $INFLUX_LOCAL_TOKEN
    echo $INFLUX_LOCAL_ORG
    echo $INFLUX_LOCAL_BUCKET
    ```


#### Container logging

The easiest way is to set up a tmux session as follows:

```
tmux new-session -d -s container-logs
tmux split-window -h -t container-logs
tmux send-keys -t container-logs:0.0 'docker logs -f subscriber1' C-m
tmux send-keys -t container-logs:0.1 'docker logs -f subscriber2' C-m
tmux attach -t container-logs
```

Logs for Influx and Grafana:
```
tmux new-session -d -s metrics-logs
tmux split-window -h -t metrics-logs
tmux send-keys -t metrics-logs:0.0 'docker logs -f pubmetrics' C-m
tmux send-keys -t metrics-logs:0.1 'docker logs -f grafana' C-m
tmux attach -t metrics-logs
```



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

## Replication risks

The following are straight from GPT.

### Risks from replication


Logical replication in PostgreSQL is a powerful feature that allows you to replicate specific tables from one database to another, potentially even between different PostgreSQL versions. However, like all replication methods, there are risks and considerations to be aware of:

1. **Version Compatibility**: Although logical replication allows replication between different PostgreSQL versions, it's important to understand any breaking changes or compatibility issues between versions.

2. **Schema Changes**: In a logical replication setup, schema changes are not automatically replicated. This means that any changes to the table structure (like adding or dropping columns) need to be manually performed on both the publisher and subscriber.

3. **Write Load**: Logical replication increases the write load on the publishing database due to the need to write to the replication slot.

4. **Replication Lag**: There's always the potential for replication lag. If the subscriber can't keep up with the changes on the publisher, there will be a delay in the data being replicated.

5. **Conflict Resolution**: Logical replication doesn't have built-in conflict resolution. If data is modified on both the publisher and the subscriber, it might result in conflicts that need to be manually resolved.

6. **Sequences**: If you are replicating tables with serial columns, the sequences generating the serial numbers are not replicated. This could lead to potential conflicts or overlaps in serial values.

7. **DDL Operations**: Some DDL (Data Definition Language) operations can cause replication to fail, especially those that affect the replicated tables.

8. **Monitoring and Maintenance**: Replication slots that are not actively being consumed can cause old WAL segments to be retained, leading to increased disk usage. Regular monitoring is essential to avoid running out of disk space.

9. **Subscription Failures**: If a subscription fails, it may require manual intervention to restart or reinitialize, especially if there are issues like network outages.

10. **Replication Filters**: If you're using replication filters (e.g., replicating only certain rows or columns), there's a risk of accidentally omitting important data. Additionally, filters add complexity to the replication setup.

11. **Resource Consumption**: Logical replication can increase CPU and memory consumption, especially if there are many changes to replicate.

12. **Security Concerns**: Data is sent in clear text unless SSL is configured. It's important to secure the connection between the publisher and subscriber to prevent data breaches.

13. **Dependencies**: Tables with foreign key relationships or other dependencies might pose challenges. You need to ensure related tables are replicated in the correct order to maintain data integrity.

14. **Backup and Recovery**: The backup and recovery strategy may need adjustments. For example, if you're relying on point-in-time recovery, the strategy might change due to the presence of replication slots.

When considering logical replication in PostgreSQL, it's crucial to test thoroughly in a non-production environment first. This allows you to understand the nuances and potential pitfalls, ensuring a smoother deployment in a production setting.

### Pausing replication

Pausing replication in a PostgreSQL logical replication setup can be a strategic move in various scenarios like maintenance, schema changes, or handling outages. However, there are inherent risks and considerations:

1. **WAL Accumulation on the Publisher**:
   - When replication is paused, changes continue to accumulate in the Write-Ahead Log (WAL) on the publisher side. If replication is paused for an extended period, this can cause the WAL to grow significantly, potentially filling up storage.
   - Replication slots ensure the publisher retains WAL segments necessary for the subscribers. If a subscriber isn't actively fetching and applying them, they'll keep accumulating.

2. **Potential Data Inconsistency**:
   - While replication is paused, changes continue to be made on the publisher. If any direct changes (inserts, updates, or deletes) are made on the subscriber during this time, they could result in data inconsistencies when replication is resumed.

3. **Lag in Data Availability**:
   - Pausing replication means the subscriber won't have up-to-date data. Depending on the application's needs, this can be problematic if timely data access is essential.

4. **Resumption Overhead**:
   - When replication is resumed after a long pause, there can be a substantial amount of data to synchronize. This synchronization might cause performance overhead on both the publisher (sending the data) and the subscriber (applying the data).

5. **Schema Changes**:
   - If you pause replication to make schema changes on the publisher, those changes won't automatically propagate to the subscriber. When replication is resumed, if the changes made aren't compatible with the existing replication setup, replication can break.
   - For instance, if a column is added to a table on the publisher, and replication is resumed without adding the same column on the subscriber, replication will fail.

6. **Risk of Forgetting**:
   - This might seem trivial, but it's a genuine risk. If replication is paused for maintenance or some other reason, there's a risk someone might forget to resume it. Depending on monitoring and alerting setup, this can lead to prolonged periods of replication being inactive without anyone noticing.

To mitigate these risks:

- **Monitoring and Alerts**: Ensure that monitoring is in place to track the replication lag, WAL size, and disk usage. Alerts should be configured to notify if any of these metrics reach concerning levels.

- **Documentation**: Any time replication is paused, the reason and expected duration should be documented, along with any necessary follow-up steps.

- **Testing**: Before making major changes (like schema updates), test the process in a non-production environment to ensure smooth operations in production.

In conclusion, while pausing replication can be beneficial in certain scenarios, it's essential to be aware of the risks and manage the process carefully.
