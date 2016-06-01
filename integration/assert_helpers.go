package main

import (
	"fmt"

	"github.com/stretchr/testify/assert"
)

type testingT struct {
	lastError error
}

func (t *testingT) Errorf(format string, args ...interface{}) {
	t.lastError = fmt.Errorf(format, args)
	fmt.Printf(format, args...)
}

func assertEqual(expected, actual interface{}) error {
	t := &testingT{}
	if !assert.Equal(t, expected, actual) {
		return t.lastError
	}

	return nil
}

func assertNotEmpty(object interface{}) error {
	t := &testingT{}
	if !assert.NotEmpty(t, object) {
		return t.lastError
	}

	return nil
}
