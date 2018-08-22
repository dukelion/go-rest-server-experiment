# build stage
FROM golang:alpine AS build-env
ENV PROJECT_PATH=/go/src/github.com/dukelion/unity-test
RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		make \
		git
ADD . ${PROJECT_PATH}
RUN export GOPATH=/go;\
	cd ${PROJECT_PATH} && make build

# final stage
FROM alpine
ENV PROJECT_PATH=/go/src/github.com/dukelion/unity-test
RUN apk add --no-cache ca-certificates 
WORKDIR /app
COPY --from=build-env ${PROJECT_PATH}/unity-test /app/
EXPOSE 8080
ENV UNITYTEST_REST_SOCKET=:8080
ENTRYPOINT ./unity-test