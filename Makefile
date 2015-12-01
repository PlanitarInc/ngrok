.PHONY: default server client deps fmt clean all release-all assets client-assets server-assets contributors
export GOPATH:=$(shell pwd)

BUILDTAGS=debug
BUILDFLAGS=
default: all

deps: assets
	go get $(BUILDFLAGS) -tags '$(BUILDTAGS)' -d -v ngrok/...

server: deps
	go install $(BUILDFLAGS) -tags '$(BUILDTAGS)' ngrok/main/ngrokd

fmt:
	go fmt ngrok/...

client: deps
	go install $(BUILDFLAGS) -tags '$(BUILDTAGS)' ngrok/main/ngrok

assets: client-assets server-assets

bin/go-bindata:
	GOOS="" GOARCH="" go get github.com/jteeuwen/go-bindata/go-bindata

client-assets: bin/go-bindata
	bin/go-bindata -nomemcopy -pkg=assets -tags=$(BUILDTAGS) \
		-debug=$(if $(findstring debug,$(BUILDTAGS)),true,false) \
		-o=src/ngrok/client/assets/assets_$(BUILDTAGS).go \
		assets/client/...

server-assets: bin/go-bindata
	bin/go-bindata -nomemcopy -pkg=assets -tags=$(BUILDTAGS) \
		-debug=$(if $(findstring debug,$(BUILDTAGS)),true,false) \
		-o=src/ngrok/server/assets/assets_$(BUILDTAGS).go \
		assets/server/...

release-client: BUILDTAGS=release
release-client: client

release-server: BUILDTAGS=release
release-server: server

release-all: fmt release-client release-server

all: fmt client server

clean:
	rm -rf bin/
	go clean -i -r ngrok/... || true
	rm -rf src/ngrok/client/assets/ src/ngrok/server/assets/

contributors:
	echo "Contributors to ngrok, both large and small:\n" > CONTRIBUTORS
	git log --raw | grep "^Author: " | sort | uniq | cut -d ' ' -f2- | sed 's/^/- /' | cut -d '<' -f1 >> CONTRIBUTORS


NGROK_DOCKER_IMAGE ?= ngrok
release-docker:
	make clean
	docker run --rm \
	  -v `pwd`:/src:ro \
	  -v `pwd`/bin:/out \
	  -e GOPATH=/tmp/go \
	  -e CGO_ENABLED=0 \
	  -e BUILDFLAGS="-a -ldflags '-s'" \
	  -e SRC_DIR=/tmp/go/src/github.com/PlanitarInc/ngrok \
	  planitar/dev-go bash -c ' \
	    mkdir -p $${SRC_DIR} && \
	    cp -r /src/* $${SRC_DIR} && \
	    cd $${SRC_DIR} && \
	    make clean && \
	    make release-all && \
	    cp -r bin/ /out/docker'
	docker build -t ${NGROK_DOCKER_IMAGE} .
