.PHONY: clean build deploy 

clean:
	rm -rf build/* bin/*

build:
	command -v ssgen || go get github.com/ktravis/ssgen && go install github.com/ktravis/ssgen
	PATH=$$(go env GOPATH)/bin:$$PATH ssgen -in src -out build
	cp -R static/ build/
