package server

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetConfig(t *testing.T) {
	os.Clearenv()
	os.Setenv("UNITYTEST_REST_SOCKET", ":8090")
	c, err := ConfigGet()
	assert.NoError(t, err)
	assert.Equal(t, ":8090", c.RESTSocket)
}
