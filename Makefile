.PHONY:	docker setup compile

DOCKER_TAG ?= graf

compile: setup
	mix compile

docker:
	docker build . -t $(DOCKER_TAG)

setup:
	mix local.hex --force
	mix deps.get
	cd priv/heb && npm install

test: compile
	mix test
