APP_BINARY=goColorGrpc 
APP_IMAGE=go-color-grpc

build:
	@echo "Building docker image..."
	docker build -t ${APP_IMAGE} .
	@echo "Done."

up:
	docker run -d -p 50001:50001 ${APP_IMAGE} 

down:
	docker rm $$(docker stop $$(docker ps -a -q --filter ancestor=${APP_IMAGE} --format="{{.ID}}"))

proto:
	protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative graph/graph.proto