package payload

import (
	"encoding/json"
	"fmt"
	"gopkg.in/validator.v2"
	"io"
	"net"
	"reflect"
	"strconv"
)

// Data is json object we're processing
type Data struct {
	Ts         *json.Number            `json:"ts,Number" validate:"nonzero,isTimestamp"`
	Sender     *string                 `json:"sender" validate:"nonzero"`
	Message    *map[string]interface{} `json:"message" validate:"nonzero,isJsonmap"`
	SentFromIP *string                 `json:"sent-from-ip,omitempty" validate:"isIPv4orEmpty"`
	Priority   *int                    `json:"priority,omitempty"`
}

// Process is the function to unmarshal and validate payload
func Process(payload io.Reader) ([]byte, error) {
	var result Data
	dec := json.NewDecoder(payload)
	dec.DisallowUnknownFields()
	err := dec.Decode(&result)
	if err != nil {
		return nil, err
	}
	v := validator.NewValidator()
	err = v.SetValidationFunc("isTimestamp", isTimestamp)
	if err != nil {
		return nil, err
	}
	err = v.SetValidationFunc("isJsonmap", isJsonmap)
	if err != nil {
		return nil, err
	}
	err = v.SetValidationFunc("isIPv4orEmpty", isIPv4orEmpty)
	if err != nil {
		return nil, err
	}
	err = v.Validate(result)
	if err != nil {
		return nil, err
	}
	var strresult []byte
	strresult, err = json.Marshal(result)
	if err != nil {
		return nil, err
	}

	return strresult[:], nil
}

func isTimestamp(val interface{}, param string) error {
	ts := reflect.ValueOf(val).String()
	_, err := strconv.ParseUint(ts, 10, 64)
	return err
}
func isJsonmap(val interface{}, param string) error {
	if reflect.TypeOf(val).Kind() != reflect.Map {
		return fmt.Errorf("Is not map")
	}
	if len(val.(map[string]interface{})) == 0 {
		return fmt.Errorf("Is empty map")
	}
	return nil
}
func isIPv4orEmpty(val interface{}, param string) error {
	if reflect.ValueOf(val).Kind() == reflect.Ptr && reflect.ValueOf(val).IsNil() {
		return nil // Nil is ok here
	}
	ip := reflect.ValueOf(val).String()
	result := net.ParseIP(ip).To4()
	if result == nil {
		return fmt.Errorf("Is not a valid IPv4")
	}
	return nil
}
