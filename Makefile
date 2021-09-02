include make/general/Makefile
STACK         := laravel
NETWORK       := proxylampy
include make/docker/Makefile

DOCKER_EXECPHP := @docker exec $(STACK)_phpfpm.1.$$(docker service ps -f 'name=$(STACK)_phpfpm' $(STACK)_phpfpm -q --no-trunc | head -n1)

SUPPORTED_COMMANDS := composer linter
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMAND_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMAND_ARGS):;@:)
endif

COMPOSER_EXEC := ${DOCKER_EXECPHP} composer

apps/composer.lock: isdocker apps/composer.json
	${COMPOSER_EXEC} update

apps/vendor: isdocker apps/composer.json
	${COMPOSER_EXEC} install --no-progress --prefer-dist --optimize-autoloader

composer: isdocker ### Scripts for composer
ifeq ($(COMMAND_ARGS),suggests)
	${COMPOSER_EXEC} suggests --by-suggestion
else ifeq ($(COMMANDS_ARGS),outdated)
	${COMPOSER_EXEC} outdated
else ifeq ($(COMMANDS_ARGS),fund)
	${COMPOSER_EXEC} fund
else ifeq ($(COMMANDS_ARGS),prod)
	${COMPOSER_EXEC} install --no-dev --no-progress --prefer-dist --optimize-autoloader
else ifeq ($(COMMANDS_ARGS),dev)
	${COMPOSER_EXEC} install --no-progress --prefer-dist --optimize-autoloader
else ifeq ($(COMMANDS_ARGS),u)
	${COMPOSER_EXEC} update
else ifeq ($(COMMANDS_ARGS),i)
	${COMPOSER_EXEC} install
else ifeq ($(COMMANDS_ARGS),validate)
	${COMPOSER_EXEC} validate
else
	@printf "${MISSING_ARGUMENTS}" "composer"
	@printf "${NEED}" "suggests" "suggestions package pour PHP"
	@printf "${NEED}" "i" "install"
	@printf "${NEED}" "outdated" "Packet php outdated"
	@printf "${NEED}" "fund" "Discover how to help fund the maintenance of your dependencies."
	@printf "${NEED}" "prod" "Installation version de prod"
	@printf "${NEED}" "dev" "Installation version de dev"
	@printf "${NEED}" "u" "COMPOSER update"
	@printf "${NEED}" "validate" "COMPOSER validate"
endif

install: node_modules ## Installation
	@make docker deploy -i

linter: node_modules isdocker ### Scripts Linter
ifeq ($(COMMAND_ARGS),all)
	@make linter readme -i
else ifeq ($(COMMAND_ARGS),readme)
	@npm run linter-markdown README.md
else
	@printf "${MISSING_ARGUMENTS}" linter
	@printf "${NEED}" "all" "## Launch all linter"
	@printf "${NEED}" "readme" "linter README.md"
endif