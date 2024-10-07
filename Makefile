all: compose.yaml

compose.yaml: compose.jsonnet
	jsonnet $(JSONNET_ARGS) $< | yq -y > $@ || { rm -f $@; exit 1; }

clean:
	rm -f compose.yaml
