LEVEL4_RELEASE_PATH="/level4/_build/dev/rel/level4"

level4: ./dockerfiles/level4.Dockerfile
	make -C ./level4 release
	docker build \
		--build-arg LEVEL4_RELEASE_PATH=${LEVEL4_RELEASE_PATH} \
		-f ./dockerfiles/level4.Dockerfile \
		-t level4:latest .
	docker tag level4:latest \
		registry.wsantos.net/tradingmachines/level4:latest

all: level4
