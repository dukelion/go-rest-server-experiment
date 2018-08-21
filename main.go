package main

import (
	"github.com/Sirupsen/logrus"
	"github.com/dukelion/unity-test/server"
)

func main() {
	conf, err := server.ConfigGet()
	if err != nil {
		logrus.Fatal(err)
	}
	srv, err := server.NewUnityTest(conf)
	if err != nil {
		logrus.Fatal(err)
	}
	logrus.Fatal(srv.Start())
}
