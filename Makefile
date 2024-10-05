all: compose.yaml

compose.yaml: compose.jsonnet
	jsonnet $< | yq -y > $@ || { rm -f $@; exit 1; }
