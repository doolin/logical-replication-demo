# Production @ Home

This project started as an investigation into implementing logical replication between various Postgres databases running in containers on a Macbook. Over time, it has evolved into a more general purpose investigation of production toolchains for operating web applications. While "full scale" simulation is not possible, a modern Macbook with Docker containers allows constructing a reasonable facsimile which can be stressed in ways similar to how production environments are stressed. For example, running a Postgres database or a Rails application in very small containers will induce similar errors under loads easy to script from a Macbook.

A project like this is open-ended. The rabbit hole goes very, very deep.

## What's in the box?

The cool thing about this sort of project is it enables investigation into many aspects of how web applications operate. Here's a few:

- [Postgres logical replication](./logical-replication.md)
- [Monitoring with Influx and Grafana](./monitoring.md)

## Presentations

Running the slides:
- `PORT=9876 npx @marp-team/marp-cli@latest -s deck/`
- http://localhost:9876/

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





## ETL analog (fix this later)

pg_sampler has:

    Extract data from postgres

    Transform the postgres results to influx

    Load into influx

The problem this solves is that postgres provides point values but we want trends over time.

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
5. Consider rewriting as a toolbox of different fun things people can do.
6. Monitor container stats in Grafana, creating a multi-paned dashboard.
7. Monitor other database values than locks, add to dashboard.
8. Provision grafana queries via API.


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


## Manual setup

The semi-automated procedure listed above could probably be fully automated into a single script, and in a production system that would be warranted. However, there is still value in  manually working through all the configuration steps, it provides a better understanding of how each step works, and provides opportunity to learn from any errors occurring during configuration. It proceeds as follows:

1. Prepare and operate a docker postgres instance.
2. Configure postgres localhost and docker instances for publish/subscribe.
3. Check the runtime to ensure it's operating correctly.

A running localhost instance of postgres on port 5432 is assumed.
