isDocker := $(shell docker info > /dev/null 2>&1 && echo 1)

.DEFAULT_GOAL := help
STACK         := laravel
NETWORK       := proxynetwork

APACHE         := $(STACK)_apache
APACHEFULLNAME := $(APACHE).1.$$(docker service ps -f 'name=$(APACHE)' $(APACHE) -q --no-trunc | head -n1)

PHPFPM         := $(STACK)_phpfpm
PHPFPMFULLNAME := $(PHPFPM).1.$$(docker service ps -f 'name=$(PHPFPM)' $(PHPFPM) -q --no-trunc | head -n1)

DOCKER_EXECPHP := @docker exec $(PHPFPMFULLNAME)

SUPPORTED_COMMANDS := composer sleep contributors docker logs git linter ssh tests inspect update
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

help:
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

node_modules:
	@npm install

.PHONY: isdocker
isdocker: ## Docker is launch
ifeq ($(isDocker), 0)
	@echo "Docker is not launch"
	exit 1
endif

dump:
	@mkdir dump

folders: dump ## Create folder

composer: isdocker ## Scripts for composer
ifeq ($(COMMAND_ARGS),suggests)
	$(DOCKER_EXECPHP) make composer suggests
else ifeq ($(COMMAND_ARGS),outdated)
	$(DOCKER_EXECPHP) make composer outdated
else ifeq ($(COMMAND_ARGS),fund)
	$(DOCKER_EXECPHP) make composer fund
else ifeq ($(COMMAND_ARGS),prod)
	$(DOCKER_EXECPHP) make composer prod
else ifeq ($(COMMAND_ARGS),dev)
	$(DOCKER_EXECPHP) make composer dev
else ifeq ($(COMMAND_ARGS),update)
	$(DOCKER_EXECPHP) make composer update
else ifeq ($(COMMAND_ARGS),validate)
	$(DOCKER_EXECPHP) make composer validate
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make composer ARGUMENT"
	@echo "---"
	@echo "suggests: suggestions package pour PHP"
	@echo "outdated: Packet php outdated"
	@echo "fund: Discover how to help fund the maintenance of your dependencies."
	@echo "prod: Installation version de prod"
	@echo "dev: Installation version de dev"
	@echo "update: COMPOSER update"
	@echo "validate: COMPOSER validate"
endif

contributors: node_modules ## Contributors
ifeq ($(COMMAND_ARGS),add)
	@npm run contributors add
else ifeq ($(COMMAND_ARGS),check)
	@npm run contributors check
else ifeq ($(COMMAND_ARGS),generate)
	@npm run contributors generate
else
	@npm run contributors
endif

.PHONY: sleep
sleep: ## sleep
	@sleep  $(COMMAND_ARGS)

docker: isdocker ## Scripts docker
ifeq ($(COMMAND_ARGS),create-network)
	@docker network create --driver=overlay $(NETWORK)
else ifeq ($(COMMAND_ARGS),image-pull)
	@more docker-compose.yml | grep image: | sed -e "s/^.*image:[[:space:]]//" | while read i; do docker pull $$i; done
else ifeq ($(COMMAND_ARGS),deploy)
	@docker stack deploy -c docker-compose.yml $(STACK)
else ifeq ($(COMMAND_ARGS),ls)
	@docker stack services $(STACK)
else ifeq ($(COMMAND_ARGS),stop)
	@docker stack rm $(STACK)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make docker ARGUMENT"
	@echo "---"
	@echo "create-network: create network"
	@echo "deploy: deploy"
	@echo "image-pull: Get docker image"
	@echo "ls: docker service"
	@echo "stop: docker stop"
endif

logs: isdocker ## Scripts logs
ifeq ($(COMMAND_ARGS),stack)
	@docker service logs -f --tail 100 --raw $(STACK)
else ifeq ($(COMMAND_ARGS),apache)
	@docker service logs -f --tail 100 --raw $(APACHEFULLNAME)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service logs -f --tail 100 --raw $(PHPFPMFULLNAME)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make logs ARGUMENT"
	@echo "---"
	@echo "stack: logs stack"
	@echo "apache: APACHE"
	@echo "phpfpm: PHPFPM"
endif

git: node_modules ## Scripts GIT
ifeq ($(COMMAND_ARGS),status)
	@git status
else ifeq ($(COMMAND_ARGS),check)
	@make composer validate -i
	@make composer outdated -i
	@make bdd validate -i
	@make contributors check -i
	@make linter all -i
	@make git status -i
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make git ARGUMENT"
	@echo "---"
	@echo "check: CHECK before"
	@echo "status: status"
endif

install: folders node_modules ## Installation
	@make docker deploy -i

linter: node_modules isdocker ## Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),readme)
	@npm run linter-markdown README.md
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make linter ARGUMENT"
	@echo "---"
	@echo "all: ## Launch all linter"
	@echo "readme: linter README.md"
endif

ssh: isdocker ## SSH
ifeq ($(COMMAND_ARGS),apache)
	@docker exec -it $(APACHEFULLNAME) /bin/bash
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker exec -it $(PHPFPMFULLNAME) /bin/bash
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make ssh ARGUMENT"
	@echo "---"
	@echo "apache: APACHE"
	@echo "phpfpm: PHPFPM"
endif

inspect: isdocker ## inspect
ifeq ($(COMMAND_ARGS),apache)
	@docker service inspect $(APACHE)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service inspect $(PHPFPM)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make inspect ARGUMENT"
	@echo "---"
	@echo "apache: APACHE"
	@echo "phpfpm: PHPFPM"
endif

update: isdocker ## ssh
ifeq ($(COMMAND_ARGS),apache)
	@docker service update $(APACHE)
else ifeq ($(COMMAND_ARGS),phpfpm)
	@docker service update $(PHPFPM)
else
	@echo "ARGUMENT missing"
	@echo "---"
	@echo "make update ARGUMENT"
	@echo "---"
	@echo "apache: APACHE"
	@echo "phpfpm: PHPFPM"
endif
