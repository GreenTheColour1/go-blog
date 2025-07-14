package posts

import (
	"bytes"
	"embed"
	"time"

	chromahtml "github.com/alecthomas/chroma/v2/formatters/html"
	"github.com/yuin/goldmark"
	highlighting "github.com/yuin/goldmark-highlighting/v2"
)

type Post struct {
	Id         [32]byte  `field:"id"`
	Created_at time.Time `field:"created_at"`
	Updated_at time.Time `field:"updated_at"`
	Title      string    `field:"title"`
	Filename   string    `field:"filename"`
	Slug       string    `field:"slug"`
	Body       []byte
	RawHTML    string
}

//go:embed files/*.md
var PostAssets embed.FS

func (p *Post) ConvertBodyToHTML() {
	markdown := goldmark.New(goldmark.WithExtensions(
		highlighting.NewHighlighting(
			highlighting.WithStyle("gruvbox"),
			highlighting.WithFormatOptions(
				chromahtml.WithLineNumbers(true),
			),
		),
	))

	var buf bytes.Buffer

	if err := markdown.Convert(p.Body, &buf); err != nil {
		panic(err)
	}

	p.RawHTML = buf.String()
}
