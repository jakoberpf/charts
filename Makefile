minikube-create:
	@minikube start

deploy:
	@.github/deploy-istio.sh
	@.github/deploy-secrets.sh
	@.github/deploy-tls.sh
	@.github/deploy-charts.sh
	@.github/test-istio.sh

test: deploy
	@echo "Finished Testing"
