.PHONY: clean build deploy 

clean:
	rm -rf build/* bin/*

build: $(SSGEN_BIN)
	command -v ssgen || go install github.com/ktravis/ssgen@latest
	ssgen -in src -out build
	cp -R static/ build/
