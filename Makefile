.PHONY: clean build deploy 

GOPATH ?= $(shell go env GOPATH)
GOBIN ?= $(GOPATH)/bin
SSGEN := $(GOBIN)/ssgen
PORT := 8081

build: $(SSGEN)
	$(SSGEN) -in src -out build
	cp -R static/ build/

$(SSGEN):
	go install github.com/ktravis/ssgen@latest

serve: $(SSGEN)
	$(SSGEN) -serve localhost:$(PORT)

clean:
	rm -rf build/* bin/*
