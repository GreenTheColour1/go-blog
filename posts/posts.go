package posts

import (
	"embed"
	"time"
)

type Post struct {
	Id         [32]byte  `field:"id"`
	Created_at time.Time `field:"created_at"`
	Updated_at time.Time `field:"updated_at"`
	Title      string    `field:"title"`
	Filename   string    `field:"filename"`
	Slug       string    `field:"slug"`
	Body       string
}

//go:embed files/*.md
var PostAssets embed.FS
