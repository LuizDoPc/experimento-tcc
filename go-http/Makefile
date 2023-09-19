APP_BINARY=goColorHttp 
APP_IMAGE=go-color-http

build:
	@echo "Building docker image..."
	docker build -t ${APP_IMAGE} .
	@echo "Done."

up:
	docker run -d -p 8080:8080 ${APP_IMAGE} 

down:
	docker rm $$(docker stop $$(docker ps -a -q --filter ancestor=${APP_IMAGE} --format="{{.ID}}"))