FROM registry.services.schubergphilis.com:5000/saas/microservice-builder

ADD . /go/src/sbp.gitlab.schubergphilis.com/api/myservice
WORKDIR /go/src/sbp.gitlab.schubergphilis.com/api/myservice
RUN go install
RUN echo '[{"name":"authservice", "version": "v1", "address": "authservice:9000"}]' > /services.json
CMD echo "Building myservice..." && go build -o ./myservice && until nc -z -w 2 myservice_db 3306; do sleep 1; done && ./myservice migrateDB && ./myservice --dev-mode --discovery-overrides /services.json

EXPOSE 8000
EXPOSE 9000
