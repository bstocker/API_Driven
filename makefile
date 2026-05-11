# --- Variables de l'environnement Codespaces (Zéro Localhost) ---
PUBLIC_ENDPOINT = https://$(CODESPACE_NAME)-4566.$(GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN)
AWS_CMD = aws --endpoint-url=$(PUBLIC_ENDPOINT) --region us-east-1

# --- Commandes Principales ---

# Déploie l'architecture complète (Instance, Lambda, API)
deploy:
	@chmod +x deploy.sh
	@./deploy.sh

# Affiche l'état des instances EC2 dans le terminal
status:
	@echo "Vérification de l'état des instances sur LocalStack..."
	@$(AWS_CMD) ec2 describe-instances --query 'Reservations[*].Instances[*].{ID:InstanceId,State:State.Name}' --output table

# Affiche les URLs cliquables pour le pilotage via navigateur
urls:
	@$(eval API_ID=$(shell $(AWS_CMD) apigateway get-rest-apis --query 'items[0].id' --output text))
	@echo "------------------------------------------------"
	@echo "🚀 URLs DE PILOTAGE (Format Professeur) :"
	@echo "START  : $(PUBLIC_ENDPOINT)/restapis/$(API_ID)/prod/_user_request_/start"
	@echo "STOP   : $(PUBLIC_ENDPOINT)/restapis/$(API_ID)/prod/_user_request_/stop"
	@echo "STATUS : $(PUBLIC_ENDPOINT)/restapis/$(API_ID)/prod/_user_request_/status"
	@echo "------------------------------------------------"

# Nettoie les fichiers temporaires
clean:
	@rm -f function.zip
	@echo "Nettoyage terminé."
