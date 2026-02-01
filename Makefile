NAME=inception

RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[0;33m
RESET = \033[0m

COMPOSE = ./srcs/docker-compose.yml
ENV = ./srcs/.env

all: env_check data_base build

env_check:
	@if [ ! -f $(ENV) ]; then \
		echo "$(RED)Error: could not find environment variables$(RESET)"; \
		exit 1; \
	fi

data_base:
	@mkdir -p $(HOME)/flima/data/mariadb
	@mkdir -p $(HOME)/flima/data/wordpress
	@echo "$(GREEN)Data base folder created\n$(RESET)"

build:
	@docker compose -f $(COMPOSE) up --build -d

down:
	@docker compose -f $(COMPOSE) down

clean: down
	@docker system prune -af
	@docker volume prune -f
	@echo "$(GREEN) Docker environment fully cleaned.$(RESET)"

fclean: clean
	@docker compose -f $(COMPOSE) down --volumes
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker rmi -f $$(docker images -q) 2>/dev/null || true
	@sudo rm -rf $(HOME)/flima/
	@echo "$(GREEN)Full cleanup completed: Docker resources and persistent data were permanently removed.$(RESET)"

# CHECK IT 
re: down build 
	@echo "$(GREEN)Containers rebuilt and environment restarted successfully.$(RESET)"


.PHONY: all data_base env_check build down clean fclean re
