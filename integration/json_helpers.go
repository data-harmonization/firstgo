package main

import (
	"encoding/json"
	"fmt"
)

func readFromJSONList(jsonBody string) ([]interface{}, error) {
	var m []interface{}
	err := json.Unmarshal([]byte(jsonBody), &m)
	if err != nil {
		return nil, fmt.Errorf("Error parsing json: %+v", err)
	}

	return m, nil
}
func readFromJSONObject(jsonBody string) (map[string]interface{}, error) {
	var m map[string]interface{}
	err := json.Unmarshal([]byte(jsonBody), &m)
	if err != nil {
		return nil, fmt.Errorf("Error parsing json: %+v", err)
	}

	return m, nil
}

func writeJSON(request map[string]interface{}) (string, error) {
	bytes, err := json.Marshal(request)
	if err != nil {
		return "", err
	}

	return string(bytes), nil
}
