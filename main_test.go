package main

import (
	"os"
	"strings"
	"testing"

	"sbp.gitlab.schubergphilis.com/api/microservice/test"
)

func TestMainApp(t *testing.T) {
	// set the arguments:
	os.Args = []string{"test", "about"}

	output := test.CaptureOutput(func() {
		main()
	})

	if !strings.Contains(output, "NAME: myservice") {
		t.Fatalf("Expected service name to be in the about call, got %s", output)
	}
}
