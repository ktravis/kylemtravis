.PHONY: clean build deploy 

clean:
	rm -rf build/*

build:
	which ssgen || go get github.com/ktravis/ssgen
	$(go env GOPATH)/bin/ssgen -in src -out build
	cp -R static/ build/

deploy: build
	gsutil -m rsync -r build/ gs://kylemtravis.com/
