package payload

import (
	"bytes"
	"github.com/stretchr/testify/assert"
	"testing"
)

type TestJSON struct {
	json        []byte
	description string
	shouldFail  bool
}

func TestProcess(t *testing.T) {
	var tests []TestJSON
	tests = append(tests, TestJSON{json: []byte(`{
		"sender": "testy-test-service",
		"message": {
			"foo": "bar",
			"baz": "bang"
		},
		"sent-from-ip": "1.2.3.4",
		"priority": 2
	}`), description: "No ts field", shouldFail: true})

	tests = append(tests, TestJSON{json: []byte(`{
		"ts": "Wed Aug 22 00:06:45 +06 2018",
		"sender": "testy-test-service",
		"message": {
			"foo": "bar",
			"baz": "bang"
		},
		"sent-from-ip": "1.2.3.4",
		"priority": 2
	}`), description: "Ts is not unix timestamp", shouldFail: true})

	tests = append(tests, TestJSON{json: []byte(`{
		"ts": "1530228282",
		"message": {
			"foo": "bar",
			"baz": "bang"
		},
		"sent-from-ip": "1.2.3.4",
		"priority": 2
	}`), description: "No sender field", shouldFail: true})

	tests = append(tests, TestJSON{json: []byte(`{
		"ts": "1530228282",
		"sender": "testy-test-service",
		"sent-from-ip": "1.2.3.4",
		"priority": 2
	}`), description: "no message field", shouldFail: true})

	tests = append(tests, TestJSON{json: []byte(`{
		"ts": "1530228282",
		"sender": "testy-test-service",
		"message": {},
		"sent-from-ip": "1.2.3.4",
		"priority": 2
	}`), description: "message empty", shouldFail: true})

	tests = append(tests, TestJSON{json: []byte(`{
		"ts": "1530228282",
		"sender": "testy-test-service",
		"message": "message",
		"sent-from-ip": "1.2.3.4",
		"priority": 2
	}`), description: "message is not json", shouldFail: true})

	tests = append(tests, TestJSON{json: []byte(`{
		"unknown": "111",
		"ts": "1530228282",
		"sender": "testy-test-service",
		"message": {
			"foo": "bar",
			"baz": "bang"
		},
		"priority": 2
	}`), description: "extra fields not acceptable", shouldFail: true})

	tests = append(tests, TestJSON{json: []byte(`{
		"ts": "1530228282",
		"sender": "testy-test-service",
		"message": {
			"foo": "bar",
			"baz": "bang"
		},
		"sent-from-ip": "301.2.3.4",
		"priority": 2
	}`), description: "Sent-from-ip is not valid IPv4", shouldFail: true})

	tests = append(tests, TestJSON{json: []byte(`{
		invalid json string
	}`), description: "invalid json not acceptable", shouldFail: true})

	tests = append(tests, TestJSON{json: []byte(`{
		"ts": "1530228282",
		"sender": "testy-test-service",
		"message": {
			"foo": "bar",
			"baz": "bang"
		},
		"sent-from-ip": "1.2.3.4",
		"priority": 2
	}`), description: "normal payload that is ok", shouldFail: false})

	tests = append(tests, TestJSON{json: []byte(`{
		"ts": "1530228282",
		"sender": "testy-test-service",
		"message": {
			"foo": "bar",
			"baz": "bang"
		},
		"priority": 2
	}`), description: "no sent-from-ip is ok", shouldFail: false})

	tests = append(tests, TestJSON{json: []byte(`{
		"sent-from-ip": "1.2.3.4",
		"sender": "testy-test-service",
		"message": {
			"foo": "bar",
			"baz": "bang"
		},
		"ts": "1530228282",
		"priority": 2
	}`), description: "field reorder is ok", shouldFail: false})

	var err error
	// var result *Data
	for i := 0; i < len(tests); i++ {
		_, err = Process(bytes.NewReader(tests[i].json))
		if tests[i].shouldFail {
			assert.Errorf(t, err, "test case %d no error where it should be\ndescription: %s\njson: %s", i, tests[i].description, tests[i].json)
		} else {
			assert.NoErrorf(t, err, "test case %d has error description: %s\njson:%s", i, tests[i].description, tests[i].json)
		}
	}
}
