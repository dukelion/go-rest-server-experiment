package server

import (
	"net/http"
	"os"

	"github.com/Sirupsen/logrus"
	"github.com/dukelion/unity-test/payload"
	"github.com/gorilla/mux"
	"github.com/iron-io/iron_go3/mq"
	"github.com/kelseyhightower/envconfig"
)

// Config is configuration structure for REST server
type Config struct {
	RESTSocket string `envconfig:"REST_SOCKET" required:"true"`
}

// ConfigGet parses ExchangeConfig from env vars
func ConfigGet() (Config, error) {
	var c Config
	err := envconfig.Process("UnityTest", &c)
	return c, err
}

// UnityTest is the REST Server
type UnityTest struct {
	config Config
	logger *logrus.Logger
	queue  mq.Queue
}

// NewUnityTest creates REST server instance
func NewUnityTest(cfg Config) (*UnityTest, error) {
	srv := &UnityTest{config: cfg}
	logrus.SetFormatter(&logrus.JSONFormatter{})
	logrus.SetOutput(os.Stdout)
	logrus.SetLevel(logrus.WarnLevel)
	srv.logger = logrus.New()
	srv.queue = mq.New("test_queue")
	return srv, nil
}

// ProcessPayload gets json body of request, validates it and puts to message queue
func (srv *UnityTest) ProcessPayload(w http.ResponseWriter, r *http.Request) {
	payload, err := payload.Process(r.Body)
	if err != nil {
		srv.logger.Errorf("Error while processing: %s", err.Error())
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	strpayload := string(payload[:])
	srv.logger.Infof("Message :%s\n", strpayload)
	var id string
	id, err = srv.queue.PushMessage(mq.Message{Delay: 0, Body: strpayload})

	if err != nil {
		srv.logger.Errorf("Error while processing: %s", err.Error())
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	srv.logger.Infof("Message posted with id %s", id)
}

// Start launching REST server
func (srv *UnityTest) Start() error {
	mux := mux.NewRouter()
	mux.HandleFunc("/payload", srv.ProcessPayload).Methods("POST")
	srv.logger.Infof("REST is listening on %s", srv.config.RESTSocket)
	return http.ListenAndServe(srv.config.RESTSocket, mux)
}
