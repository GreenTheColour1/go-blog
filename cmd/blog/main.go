package main

import (
	"github.com/GreenTheColour1/go-blog/database"
	"github.com/GreenTheColour1/go-blog/server"
)

func main() {
	s := server.Server{}

	s.Start()
	database.Connect()
}
