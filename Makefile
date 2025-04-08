.PHONY: clean build deploy 

clean:
	rm -rf build/* bin/*

build:
	command -v ssgen || go get github.com/ktravis/ssgen@latest
	PATH=$$(go env GOPATH)/bin:$$PATH ssgen -in src -out build
	cp -R static/ build/
