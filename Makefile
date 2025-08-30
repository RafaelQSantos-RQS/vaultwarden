.DEFAULT_GOAL := help

ifneq (,$(wildcard ./.env))
	include ./.env
	export
endif

COMPOSE_COMMAND           = docker compose --env-file .env

ENV_FILE                  = .env
ENV_TEMPLATE              = .env.template

EXTERNAL_NETWORK_NAME    ?= web
POSTGES_DATA_VOLUME_NAME ?= vaultwarden-pgdata

.PHONY: help setup up down restart sync status logs pull validate _check-env-exists _create-env-from-template _create-network-if-not-exists _create-volume-if-not-exists

help: ## 🤔 Show this help message
	@echo "\033[1;33mAvailable commands:\033[0m"
	@grep -h -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup: ## 🛠️ Prepare the enviroment
	@echo "==> Preparing the environment..."
	@$(MAKE) _check-env-exists
	@$(MAKE) _create-network-if-not-exists
	@$(MAKE) _create-volume-if-not-exists
	@echo "The environment is ready. ☑️"

_check-env-exists:
	@if [ -f $(ENV_FILE) ]; then \
		echo "==> $(ENV_FILE) already exists"; \
		echo "==> Nothing will be done." ; \
	else \
		$(MAKE) _create-env-from-template; \
	fi

_create-env-from-template:
	@echo "==> $(ENV_FILE) not found. Creating from template..."
	@if [ ! -f $(ENV_TEMPLATE) ]; then \
		echo "❌ No $(ENV_TEMPLATE) found. Cannot continue."; \
		exit 1; \
	fi
	@cp $(ENV_TEMPLATE) $(ENV_FILE)
	@echo "⚠️ Please edit $(ENV_FILE) with your custom values."

_create-network-if-not-exists:
	@echo "==> Checking for network $(EXTERNAL_NETWORK_NAME)..."
	@docker network inspect $(EXTERNAL_NETWORK_NAME) >/dev/null 2>&1 || \
		(echo "==> Network $(EXTERNAL_NETWORK_NAME) not found. Creating..." && docker network create $(EXTERNAL_NETWORK_NAME))
	@echo "✅ Network $(EXTERNAL_NETWORK_NAME) is ready."

_create-volume-if-not-exists:
	@echo "==> Checking for volume $(POSTGES_DATA_VOLUME_NAME)..."
	@docker volume inspect $(POSTGES_DATA_VOLUME_NAME) >/dev/null 2>&1 || \
		(echo "==> Volume $(POSTGES_DATA_VOLUME_NAME) not found. Creating..." && docker volume create $(POSTGES_DATA_VOLUME_NAME))
	@echo "✅ Volume $(POSTGES_DATA_VOLUME_NAME) is ready."

sync: ## 🔄 Syncs the local code with the remote 'main' branch (discards local changes!).
	@echo "==> Syncing with the remote repository (origin/main)..."
	@git fetch origin
	@git reset --hard origin/main
	@echo "Sync completed. Directory is clean and up-to-date."

up: ## 🚀 Start containers
	@${COMPOSE_COMMAND} up -d --remove-orphans

down: ## 🛑 Stop containers
	@${COMPOSE_COMMAND} down

restart: ## 🔄 Restart containers
	@$(MAKE) down
	@$(MAKE) up

status: ## 📊 Show container status
	@${COMPOSE_COMMAND} ps

logs: ## 📜 Show logs in real time
	@${COMPOSE_COMMAND} logs --follow

pull: ## 📥 Pull images
	@${COMPOSE_COMMAND} pull

validate: ## ✅ Validate the configuration file syntax.
	@${COMPOSE_COMMAND} config

%: ## Generic target to catch unknown commands.
	@echo "🚫🚫 Error: Command not found. Please use 'make help' to see available commands."
