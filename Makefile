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

clean:
	rm -f $(SVG_OUTPUT) $(PNG_OUTPUT)

.PHONY: all svg png clean

.PHONY: docker1 docker2
# Enter containers
docker1:
	@docker exec -it subscriber1 /bin/bash

docker2:
	@docker exec -it subscriber2 /bin/bash

.PHONY: psql-host-subscriber1 psql-host-subscriber2
# psql from host
DB_USER=postgres
DB_NAME=postgres
DB_PASSWORD=foobar

pub:
	@PGPASSWORD=$(DB_PASSWORD) psql -h localhost -p 5435 -U $(DB_USER) -d publisher @ $(DB_NAME)

sub1:
	@PGPASSWORD=$(DB_PASSWORD) psql -h localhost -p 5433 -U $(DB_USER) -d $(DB_NAME)

sub2:
	@PGPASSWORD=$(DB_PASSWORD) psql -h localhost -p 5434 -U $(DB_USER) -d $(DB_NAME)

grafana:
	@docker exec -it grafana /bin/sh