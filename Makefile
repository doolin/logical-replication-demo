# Various targets for driving specific scenarios
# Might turn into a little dsl

MERMAID_FILE= \
  images/logical-replication-architecture.mmd \
  images/sidekiq.mmd

SVG_OUTPUT= \
  images/logical-replication-architecture.svg \
  images/sidekiq.svg

PNG_OUTPUT= \
  images/logical-replication-architecture.png \
  images/sidekiq.png

all: $(SVG_OUTPUT) $(PNG_OUTPUT)

%.svg: %.mmd
	mmdc -i $< -o $@

%.png: %.mmd
	mmdc -i $< -o $@

.PHONY: all svg png clean

.PHONY: docker1 docker2 publisher telegraf
# Open bash shell on containers
docker1:
	@docker exec -it subscriber1 /bin/bash

docker2:
	@docker exec -it subscriber2 /bin/bash

grafana:
	@docker exec -it grafana /bin/bash

publisher:
	@docker exec -it publisher /bin/bash

telegraf:
	@docker exec -it telegraf /bin/bash

.PHONY: sub1 subs2 pub
# psql from host
DB_USER=postgres
DB_NAME=postgres
DB_PASSWORD=foobar

# Use psql on containers
pub:
	@PGPASSWORD=$(DB_PASSWORD) psql -h localhost -p 5435 -U $(DB_USER) -d publisher

sub1:
	@PGPASSWORD=$(DB_PASSWORD) psql -h localhost -p 5433 -U $(DB_USER) -d $(DB_NAME)

sub2:
	@PGPASSWORD=$(DB_PASSWORD) psql -h localhost -p 5434 -U $(DB_USER) -d $(DB_NAME)

shellcheck:
	shellcheck -x ./**/*.sh

clean:
	rm -rf pgbench_log* nohup.out

spotless: clean
	rm -f $(SVG_OUTPUT) $(PNG_OUTPUT)
