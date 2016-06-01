### Variables
APP=myservice
OUT_DIR=build
REPORT_DIR=report

PACKAGE_ROOT=sbp.gitlab.schubergphilis.com/api
FLAG_LOCATION=$(PACKAGE_ROOT)/$(APP)/vendor/$(PACKAGE_ROOT)
LD_FLAGS = -X $(FLAG_LOCATION)/microservice.buildNumber=$(BUILD_NUMBER) -X $(FLAG_LOCATION)/microservice.buildID=$(BUILD_ID)
LD_RELEASE_FLAGS=-w -linkmode external -extldflags '-static'
OUT_ARTIFACT=$(APP)-linux-amd64-$(BUILD_NUMBER).tar.gz
PROTOS := $(wildcard **/*.proto)

### Arguments
ifndef BUILD_NUMBER
BUILD_NUMBER := dev
endif
ifndef BUILD_ID
BUILD_ID := dev
endif
ifndef HTTP_PORT
HTTP_PORT := 0
endif

DOCKER_REGISTRY=registry.services.schubergphilis.com:5000
DOCKER_MACHINE_IP=$(shell docker-machine ip)
ifndef DOCKER_BUILD_TAG
DOCKER_BUILD_TAG := $(BUILD_NUMBER)
endif

default: run

#
# Run (Needs specific config for each microservice)
#
/tmp/$(APP)-up: docker-compose.yml Dockerfile glide.lock
	docker-compose down --remove-orphans
	docker pull $(DOCKER_REGISTRY)/saas/microservice-builder
	docker-compose pull
	docker-compose build
	docker-compose up -d
	docker-compose exec -T authservice sh -c "until nc -z -w 2 auth_db 3306; do sleep 1; done"
	docker-compose exec -T $(APP) sh -c "until nc -z -w 2 myservice_db 3306; do sleep 1; done && myservice migrateDB"
	docker-compose exec -T auth_db sh -c "mysql -h auth_db authservice < /all_fixtures.sql"
	docker-compose exec -T $(APP)_db sh -c "mysql -h myservice_db myservice < /all_fixtures.sql"
	touch /tmp/$(APP)-up

run: bootstrap up ## Boots up the environment and starts the service in a container
	docker-compose exec -T $(APP)_db sh -c "mysql -h myservice_db myservice < /all_fixtures.sql"
	docker-compose stop $(APP)
	@echo "\n\nStarting myservice...\n - http: $(DOCKER_MACHINE_IP):3081    ( Endpoints at http://$(DOCKER_MACHINE_IP):3081/myservice/v1/... )\n - grpc: $(DOCKER_MACHINE_IP):3091\n\n"
	docker-compose up --no-deps openam_stub authservice $(APP)

#
# Development
#
up: /tmp/$(APP)-up

down:
	@rm -f /tmp/$(APP)-up
	docker-compose down --remove-orphans

bootstrap: clean proto migrations ## Bootstraps the service, including creating the db and loading fixtures
	@echo "Service has been bootstrapped successfully"

full_clean: clean ## Cleans the project including the compiled proto and migrations
	@rm -rf **/*-bindata.go
	@rm -rf **/*.pb.go
	@rm -f /tmp/$(APP)-up

updatedeps: ## Updates the dependencies
	@glide update --strip-vcs --update-vendored --strip-vendor
	@rm -f /tmp/$(APP)-up

binary: $(OUT_DIR)/$(APP)

binary_in_container:
	@echo "Building binary '$(APP)' version: $(BUILD_NUMBER)-$(BUILD_ID)"
	CC=/usr/bin/x86_64-alpine-linux-musl-gcc go build -ldflags "$(LD_FLAGS) $(LD_RELEASE_FLAGS)" -o $(OUT_DIR)/$(APP)

$(OUT_DIR)/$(APP): db/migrations-bindata.go *.go proto ## Builds the microservice for the current platform.
	@echo "Building binary '$(APP)' version: $(BUILD_NUMBER)-$(BUILD_ID)"
	@mkdir -p $(@D)
	@go build -ldflags "$(LD_FLAGS)" -o $(OUT_DIR)/$(APP)

clean: ## Cleans the project
	@go clean
	@rm -rf $(OUT_DIR)
	@rm -rf $(REPORT_DIR)

migrations: db/migrations-bindata.go ## Generates migrations .go gile

db/migrations-bindata.go: db/migrations/*.sql
	@which go-bindata >/dev/null; if [ $$? -eq 1 ]; then \
		go get -v github.com/schubergphilis/go-bindata/...; \
	fi
	go-bindata -pkg db -o db/migrations-bindata.go db/migrations/

#
# QA
#
check: ## Checks codestyle and correctness
	@which gometalinter >/dev/null; if [ $$? -eq 1 ]; then \
		go get -v -u github.com/alecthomas/gometalinter; \
		gometalinter --install --update; \
	fi
	gometalinter --disable-all --enable=vet --enable=golint ./. ./service

coverage: clean ## Runs all the tests and output their coverage to XML for jenkins
	@mkdir $(REPORT_DIR)
	@which gocov >/dev/null; if [ $$? -eq 1 ]; then \
		go get -v github.com/axw/gocov/gocov; \
		go get -v github.com/AlekSi/gocov-xml; \
	fi
	@which go2xunit >/dev/null; if [ $$? -eq 1 ]; then \
		go get -v github.com/tebeka/go2xunit; \
	fi
	@gocov test ./. ./service | gocov-xml > $(REPORT_DIR)/coverage-service.xml
	@go test ./. ./service -v | go2xunit -output $(REPORT_DIR)/unittests.xml

test: ## Tests the project
	@go test ./. ./service

integration: up
	docker-compose stop $(APP)
	docker-compose up -d
	docker-compose exec -T $(APP) sh -c "until nc -z -w 2 localhost 8000; do sleep 1; done && make godog"
	docker-compose stop $(APP)

integration_in_container:
	docker-compose down --remove-orphans
	docker pull $(DOCKER_REGISTRY)/saas/microservice-builder
	docker-compose pull
	docker-compose build
	docker-compose -f docker-compose.yml up -d
	docker-compose exec -T authservice sh -c "until nc -z -w 2 auth_db 3306; do sleep 1; done"
	docker-compose exec -T $(APP) sh -c "until nc -z -w 2 myservice_db 3306; do sleep 1; done && myservice migrateDB"
	docker-compose exec -T auth_db sh -c "mysql -h auth_db authservice < /all_fixtures.sql"
	docker-compose exec -T $(APP)_db sh -c "mysql -h myservice_db myservice < /all_fixtures.sql"
	docker-compose exec -T $(APP) sh -c "until nc -z -w 2 localhost 8000; do sleep 1; done && make godog"
	docker-compose down --remove-orphans

godog:
	rm -rf integration/vendor_tmp
	mkdir integration/vendor_tmp
	cd integration/vendor_tmp && ln -s ../vendor src
	cd integration && GOPATH=`/bin/pwd`/vendor_tmp godog $(GODOG_OPTIONS) features $(GODOG_OUTPUT)

# Build pipeline (scripts executed on the build server)
#
release: check coverage integration_in_container ## Builds the microservice
	@mkdir -p $(@D)
	@make binary_in_container
	@rm -rf $(GOPATH)/artifact/$(APP)*
	@tar -zcf $(GOPATH)/artifact/$(OUT_ARTIFACT) -C ./$(OUT_DIR) $(APP)
	@echo "Project artifact created: ${OUT_ARTIFACT}"

integration_docker_jenkins:
	docker run \
		-v `/bin/pwd`:/go/src/$(PACKAGE_ROOT)/$(APP) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-e "BUILD_NUMBER=${BUILD_NUMBER}" \
		-e "BUILD_ID=${BUILD_ID}" \
		--rm --workdir=/go/src/$(PACKAGE_ROOT)/$(APP) \
		$(DOCKER_REGISTRY)/saas/microservice-builder \
		sh -c "make integration_in_container"

release_jenkins:
	docker run \
		-v `/bin/pwd`:/go/src/$(PACKAGE_ROOT)/$(APP) \
		-v `/bin/pwd`/artifact/:/go/artifact \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-e "BUILD_NUMBER=${BUILD_NUMBER}" \
		-e "BUILD_ID=${BUILD_ID}" \
		--rm --workdir=/go/src/$(PACKAGE_ROOT)/$(APP) \
		$(DOCKER_REGISTRY)/saas/microservice-builder \
		sh -c "make release && (make docker_push || echo 'Build did not result in pushing docker images')"

docker_push:
	@echo "Tagging docker images with $(DOCKER_BUILD_TAG)"
	docker tag $(DOCKER_REGISTRY)/api/$(APP)-app $(DOCKER_REGISTRY)/api/$(APP)-app:$(DOCKER_BUILD_TAG)
	docker tag $(DOCKER_REGISTRY)/api/$(APP)-db $(DOCKER_REGISTRY)/api/$(APP)-db:$(DOCKER_BUILD_TAG)
	@echo "Pushing docker images to $(DOCKER_REGISTRY)"
	docker push $(DOCKER_REGISTRY)/api/$(APP)-app:$(DOCKER_BUILD_TAG)
	docker push $(DOCKER_REGISTRY)/api/$(APP)-db:$(DOCKER_BUILD_TAG)
	@echo "Pushing docker images to $(DOCKER_REGISTRY) tagged as latest"
	docker push $(DOCKER_REGISTRY)/api/$(APP)-app:latest
	docker push $(DOCKER_REGISTRY)/api/$(APP)-db:latest

#
# Protobufs
#
proto: $(patsubst %.proto,%.pb.go,$(PROTOS)) ## Generates protobuf .g file

$(patsubst %.proto,%.pb.go,$(PROTOS)): $(PROTOS)
	protoc -I. $< --go_out=plugins=grpc:.

.PHONY: help integration

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
