.PHONY: clean build deploy 

SSGEN := $(shell go env GOPATH)/bin/ssgen
PORT := 8081

build: $(SSGEN)
	$(SSGEN) -in src -out build
	cp -R static/ build/

$(SSGEN):
	go install github.com/ktravis/ssgen@latest
	go env
	echo ${GOBIN}
	echo ${GOPATH}
	ls -la ~/go/bin

serve: $(SSGEN)
	$(SSGEN) -serve localhost:$(PORT)

clean:
	rm -rf build/* bin/*
