deploy:
	kubectl apply -f rng.yml
	kubectl apply -f hasher.yml
	kubectl apply -f webui.yml
	kubectl apply -f redis.yml
	kubectl apply -f worker.yml

teardown:
	kubectl delete \
		services/rng \
		services/hasher \
		services/webui \
		services/redis \
		deployments/rng \
		deployments/hasher \
		deployments/webui \
		deployments/redis \
		deployments/worker