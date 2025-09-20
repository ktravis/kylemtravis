.PHONY: clean build deploy 

SSGEN := $(shell go env GOPATH)/bin/ssgen
PORT := 8081

$(SSGEN):
	go install github.com/ktravis/ssgen@latest

build: $(SSGEN)
	$(SSGEN) -in src -out build
	cp -R static/ build/

serve: $(SSGEN)
	$(SSGEN) -serve localhost:$(PORT)

clean:
	rm -rf build/* bin/*
