.PHONY: clean build deploy 

clean:
	rm -rf build/*

SSGEN_BIN ?= ./ssgen

build:
	which ssgen || (  )
	$(SSGEN_BIN) -in src -out build
	cp -R static/ build/

$(SSGEN_BIN):
	go get github.com/ktravis/ssgen
	go build -o $@ github.com/ktravis/ssgen

deploy: build
	gsutil -m rsync -r build/ gs://kylemtravis.com/
