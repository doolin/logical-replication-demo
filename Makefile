# Various targets for driving specific scenarios
# Might turn into a little dsl

MERMAID_FILE=images/logical-replication-architecture.mmd
SVG_OUTPUT=images/logical-replication-architecture.svg
PNG_OUTPUT=images/logical-replication-architecture.png

all: svg png

svg:
	mmdc -i $(MERMAID_FILE) -o $(SVG_OUTPUT)

png:
	mmdc -i $(MERMAID_FILE) -o $(PNG_OUTPUT)

clean:
	rm -f $(SVG_OUTPUT) $(PNG_OUTPUT)

.PHONY: all svg png clean

