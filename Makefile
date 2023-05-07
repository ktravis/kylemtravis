.PHONY: clean build deploy 

clean:
	rm -rf build/* bin/*

build:
	command -v ssgen || go install github.com/ktravis/ssgen@latest
	PATH=$$(go env GOPATH)/bin/ssgen:$$PATH -in src -out build
	cp -R static/ build/
