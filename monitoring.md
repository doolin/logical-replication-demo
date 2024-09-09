# Monitoring Production @ Home

Docker provides a massive amount of leverage for building network applications on a single machine. Logging tools such as Grafana and Influx would be expected to run on different servers at scale. Docker is much easier than hooking up a network of physical servers, and much cheaper than purchasing all the virtual servers from a provider.

---

## Clickhouse while it's top of mind

Command line invocation:

- `clickhouse client --host localhost --port 9000 --user username --password password --database my_database`

---

## Postgres behavior monitoring

`pg_sampler` script does the following:

- Extract data from postgres
- Transform the postgres results to influx
- Load into influx

It's a sort of ETL process. The problem this solves is that postgres provides point values but we want trends over time.

---

## Telegraf

The primary challenge for Telegraf is getting user and group premissions correctly configured. Incorrect configuration manifests as the following:

```
[inputs.docker] Error in plugin: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/json?filters=%7B%22status%22%3A%7B%22running%22%3Atrue%7D%7D": dial unix /var/run/docker.sock: connect: permission denied
```

I have not yet been able to repeatedly solve this in any way other than trying a bunch of things to get it to work. Here are some commands to try:

- `stat ~/.docker/run/docker.sock` will provide more or less `ls -la` with groups.
- `-u $(id -u):$(id -g)`
- `sudo dseditgroup -o edit -a YOUR_USERNAME -t user daemon `
- This should already be created: `ln -s -f /Users/<user>/.docker/run/docker.sock /var/run/docker.sock`
- [Docker permissions](https://docs.docker.com/desktop/mac/permission-requirements/)


```
⌁68% [daviddoolin:~/src/logical-replication-demo] [ruby-3.2.2@logrep] GEN-266(+13/-0) ± stat /var/run/docker.sock
16777233 42719124 lrwxr-xr-x 1 root daemon 0 42 "Nov 21 12:45:53 2023" "Nov 21 12:45:53 2023" "Nov 21 12:45:53 2023" "Nov 21 12:45:53 2023" 4096 0 0 /var/run/docker.sock
⌁68% [daviddoolin:~/src/logical-replication-demo] [ruby-3.2.2@logrep] GEN-266(+13/-0) ± stat ~/.docker/run/docker.sock
16777233 42719445 srw-rw-rw- 1 daviddoolin docker 0 0 "Nov 21 13:03:18 2023" "Nov 21 12:48:36 2023" "Dec 16 05:12:21 2023" "Nov 21 12:48:36 2023" 4096 0 0 /Users/daviddoolin/.docker/run/docker.sock
```

### Errors

Telegraf has been the most difficult component to configure so far.

#### Permission denied

This is a well-known issue with Docker running on MacOs:
```
[inputs.docker] Error in plugin: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/json?filters=%7B%22status%22%3A%7B%22running%22%3Atrue%7D%7D": dial unix /var/run/docker.sock: connect: permission denied
```

Sadly, there is no one single way to solve it. In this case it works when the local volume is specified as `docker.sock.raw`

These were two of the most useful links of many:

- [Docker Macos permissions](https://docs.docker.com/desktop/mac/permission-requirements/)
- [docker.sock issue on github](https://github.com/docker/for-mac/issues/6823)

Debug ideas which didn't work including tinkering with owner and group:

- dscl . list /groups
- id -Gn daviddoolin


#### 401 Unauthorized

This is an API token missing or incorrect:

```
[outputs.influxdb_v2] When writing to [http://pubmetrics:8086]: failed to write metric to ruby_test (401 Unauthorized): unauthorized: unauthorized access
2023-12-22 07:17:14 2023-12-22T15:17:14Z E! [agent] Error writing to outputs.influxdb_v2: failed to send metrics to any configured server(s)
```

This will result when the InfluxDB tocken isn't provisioned into Telegraf. It can be done on startup (see Telegraf docker file) with the token provided on first login, or a new token can be created in InfluxDb and passed into Telegraf using environment variables. There is surely opportunity for improvement using cli tools for provisioning, something for the future.



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

```
from(bucket: "ruby_test")
|> range(start: v.timeRangeStart, stop: v.timeRangeStop)
|> filter(fn: (r) => r["_measurement"] == "locks")
|> filter(fn: (r) => r["_field"] == "lock_count")
|> filter(fn: (r) => r["mode"] == "AccessShareLock" or r["mode"] == "ExclusiveLock" or r["mode"] == "RowExclusiveLock" or r["mode"] == "ShareLock" or r["mode"] == "ShareUpdateExclusiveLock")
```

**Note** make sure the influxDB token is correct.

Once a dashboard is saved, the autorefresh can be set.

## InfluxDB

The goal for InfluxDB is to track all of the docker container statistics, and the Postgres execution behavior.

1. Run `./cleanup.sh`
1. remove the volume
1. restart.sh
1. replicate.sh

Basically the whole thing worked first time I tried it.

### Docker stats display

Here is a working query for InfluxDB which will display Docker stats for the Publisher container:

```
from(bucket: "ruby_test")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["container_name"] == "publisher")
  |> filter(fn: (r) => r["cpu"] == "cpu-total")
  |> filter(fn: (r) => r["_measurement"] == "docker_container_cpu")
  |> filter(fn: (r) => r["_field"] == "usage_percent")
```
#### Container logging

The easiest way is to set up a tmux session as follows.

Logs for Influx and Grafana:
```
tmux new-session -d -s metrics-logs
tmux split-window -h -t metrics-logs
tmux send-keys -t metrics-logs:0.0 'docker logs -f pubmetrics' C-m
tmux send-keys -t metrics-logs:0.1 'docker logs -f grafana' C-m
tmux attach -t metrics-logs
```
