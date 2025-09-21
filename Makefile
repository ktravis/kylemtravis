.PHONY: clean build deploy 

# annoying workaround to handle netlify
GOPATH := $(or $(GOPATH),$(shell go env GOPATH))
GOBIN := $(or $(shell go env GOBIN),$(GOPATH)/bin)
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
