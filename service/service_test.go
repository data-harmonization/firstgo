package service

import (
	"testing"

	ms "sbp.gitlab.schubergphilis.com/api/microservice"
	"sbp.gitlab.schubergphilis.com/api/microservice/test"
)

func TestServiceConfiguration(t *testing.T) {
	// set up an override for app config:
	json := test.NewTempFile(t, []byte(`[
	{"name": "authservice", "version": "v1", "address": ":9800"}
	]`))

	dsn, driver := test.MockDB()

	s, err := NewService(
		ms.WithServiceName("MyService"),
		ms.WithSQL(true),
		ms.WithDiscoveryOverrides(json),
		ms.WithDSN(dsn),
		ms.WithSQLDriver(driver),
	)
	if err != nil {
		t.Fatalf("Unexpected server instantiation error: %v", err)
	}

	if err := s.Configure(s.Server); err != nil {
		t.Fatalf("Unexpected server configuration error: %v", err)
	}
}
