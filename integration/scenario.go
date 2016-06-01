package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httputil"
	"strings"

	"sbp.gitlab.schubergphilis.com/api/microservice/log"
)

type scenario struct {
	serviceAddress string

	currentUserId string

	currentRequestBodyName string
	currentRequestBody     map[string]interface{}

	lastResponse     *http.Response
	lastResponseBody string
}

func newScenario(serviceAddress string) *scenario {
	return &scenario{
		serviceAddress: serviceAddress,
	}
}

func (s *scenario) request(method string, url string, requestBody string) error {
	// ensure the slash in the beginning:
	if !strings.HasPrefix(url, "/") {
		url = "/" + url
	}

	// compose the request:
	req, err := http.NewRequest(method, fmt.Sprintf("%s%s", s.serviceAddress, url), bytes.NewBufferString(requestBody))
	if err != nil {
		return err
	}

	// compose the header:
	header := make(http.Header)
	header["Authorization"] = []string{"Token t_microservice.test.NewMockedAuthorizedRequest"}
	req.Header = header

	// execute the request:
	d, _ := httputil.DumpRequest(req, true)
	log.Debugf("----\nRequesting %s: %s\n----", req.URL, d)
	response, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}

	// read the body:
	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return err
	}
	defer response.Body.Close()

	// set the state of the scenario:
	s.lastResponse = response
	s.lastResponseBody = string(body)

	log.Debugf("Got response: %s", s.lastResponseBody)

	return nil
}

func (s *scenario) Get(url string, args ...interface{}) error {
	url = fmt.Sprintf(url, args...)
	return s.request(http.MethodGet, url, "")
}

func (s *scenario) Post(url, requestBody string) error {
	return s.request(http.MethodPost, url, requestBody)
}
