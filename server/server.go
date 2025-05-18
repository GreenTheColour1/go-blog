package server

import (
	"log"
	"net/http"

	"github.com/GreenTheColour1/go-blog/database"
	"github.com/GreenTheColour1/go-blog/posts"
	"github.com/GreenTheColour1/go-blog/views"
	"github.com/a-h/templ"
)

type Server struct {
}

func (s *Server) Start() {
	post := posts.Post{Title: "WOWEEEEE"}
	http.Handle("/", templ.Handler(views.Home(post)))

	db := database.Connect()
	defer db.DB.Close()

	http.HandleFunc("/posts", func(w http.ResponseWriter, r *http.Request) {
		data, err := db.GetAllPosts()
		log.Println(data)
		if err != nil {
			log.Fatal(err)
		}
		views.PostsBody(data).Render(r.Context(), w)
	})

	http.HandleFunc("/post/{slug}", func(w http.ResponseWriter, r *http.Request) {
		data, err := db.GetPostBySlug(r.PathValue("slug"))
		if err != nil {
			log.Fatal(err)
		}
		views.PostBody(*data).Render(r.Context(), w)
	})

	http.ListenAndServe(":8080", nil)
}
