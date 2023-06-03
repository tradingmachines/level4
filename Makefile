LEVEL4_RELEASE_PATH="./level4/_build/dev/rel/level4"
LEVEL4_RPC_PORT="50051"

release:
	cd ./level4 && \
	mix release

image:
	docker build \
		--build-arg LEVEL4_RELEASE_PATH=${LEVEL4_RELEASE_PATH} \
		--build-arg LEVEL4_RELEASE_PATH=${LEVEL4_RELEASE_PATH} \
		-f ./level4.Dockerfile \
		-t wsantos.net/tradingmachines/level4:latest .

tag:
	docker tag wsantos.net/tradingmachines/level4:latest \
	registry.wsantos.net/tradingmachines/level4:latest

login:
	docker login registry.wsantos.net

push:
	docker push registry.wsantos.net/tradingmachines/level4:latest

level4: release image tag login push
