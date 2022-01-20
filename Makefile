include make/general/Makefile
STACK         := laravel
NETWORK       := proxylampy
include make/docker/Makefile

DOCKER_EXECPHP := @$(DOCKER_EXEC) $(STACK)_phpfpm.1.$$(docker service ps -f 'name=$(STACK)_phpfpm' $(STACK)_phpfpm -q --no-trunc | head -n1)

SUPPORTED_COMMANDS := composer linter
SUPPORTS_MAKE_ARGS := $(findstring $(firstword $(MAKECMDGOALS)), $(SUPPORTED_COMMANDS))
ifneq "$(SUPPORTS_MAKE_ARGS)" ""
  COMMANDS_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(COMMANDS_ARGS):;@:)
endif

COMPOSER_EXEC := ${DOCKER_EXECPHP} composer

apps/composer.lock: isdocker apps/composer.json
	${COMPOSER_EXEC} update

apps/vendor: isdocker apps/composer.json
	${COMPOSER_EXEC} install --no-progress --prefer-dist --optimize-autoloader

composer: isdocker ### Scripts for composer
ifeq ($(COMMANDS_ARGS),suggests)
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
	$(call array_arguments, \
		["suggests"]="suggestions package pour PHP" \
		["i"]="install" \
		["outdated"]="Packet php outdated" \
		["fund"]="Discover how to help fund the maintenance of your dependencies." \
		["prod"]="Installation version de prod" \
		["dev"]="Installation version de dev" \
		["u"]="COMPOSER update" \
		["validate"]="COMPOSER validate" \
	)
endif

install: node_modules ## Installation
	@make docker deploy -i

linter: node_modules isdocker ### Scripts Linter
ifeq ($(COMMANDS_ARGS),all)
	@make linter readme -i
else ifeq ($(COMMANDS_ARGS),readme)
	@npm run linter-markdown README.md
else
	@printf "${MISSING_ARGUMENTS}" "linter"
	$(call array_arguments, \
		["all"]="## Launch all linter" \
		["readme"]="linter README.md" \
	)
endif
bddset: ## Set bdd
	@cp database_init/01_laravel.sql lampy/mariadb_init/01_laravel.sql