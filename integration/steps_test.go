package main

import (
	"fmt"
	"os"

	"github.com/DATA-DOG/godog"
)

func Suite(s *godog.Suite) {
	var currentScenario *scenario

	s.BeforeScenario(func(interface{}) {
		// set up the scenario state:
		currentScenario = newScenario(os.Getenv("OUTPUT_SERVICE_ADDRESS"))
	})

	s.Step(`^User(\d+) gets (.+)$`, func(userLocalId int, path string) error {
		currentScenario.currentUserId = fmt.Sprintf("User_%d", userLocalId)
		return currentScenario.Get(path)
	})
	s.Step(`^the response code should be (\d+)$`, func(arg1 int) error {
		return assertEqual(arg1, currentScenario.lastResponse.StatusCode)
	})
}
