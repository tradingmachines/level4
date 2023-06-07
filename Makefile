LEVEL4_RELEASE_PATH="./level4/_build/dev/rel/level4"
LEVEL4_RPC_PORT="50051"

release:
	cd ./level4 && \
	mix release --overwrite

image:
	docker build \
		--build-arg LEVEL4_RELEASE_PATH=${LEVEL4_RELEASE_PATH} \
		--build-arg LEVEL4_RPC_PORT=${LEVEL4_RPC_PORT} \
		-t tradingmachines/level4:latest .

tag:
	docker tag tradingmachines/level4:latest \
	registry.wsantos.net/tradingmachines/level4:latest

login:
	docker login registry.wsantos.net

push:
	docker push registry.wsantos.net/tradingmachines/level4:latest

level4: release image

publish: tag level4 login push
