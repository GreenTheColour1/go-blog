package server

import (
	"log"
	"net/http"
	"os"

	"github.com/GreenTheColour1/go-blog/assets"
	"github.com/GreenTheColour1/go-blog/database"
	"github.com/GreenTheColour1/go-blog/views"
	"github.com/a-h/templ"
)

type Server struct {
}

func (s *Server) Start() {
	mux := http.NewServeMux()

	db := database.Connect()
	defer db.DB.Close()

	mux.Handle("/", templ.Handler(views.Home()))

	mux.HandleFunc("/posts", func(w http.ResponseWriter, r *http.Request) {
		data, err := db.GetAllPosts()
		if err != nil {
			log.Fatal(err)
		}
		views.PostsBody(data).Render(r.Context(), w)
	})

	mux.HandleFunc("/post/{slug}", func(w http.ResponseWriter, r *http.Request) {
		post, err := db.GetPostBySlug(r.PathValue("slug"))
		if err != nil {
			log.Fatal(err)
		}
		post.ConvertBodyToHTML()

		views.PostBody(*post).Render(r.Context(), w)
	})

	mux.Handle("/assets/", disableCacheInDevMode(http.StripPrefix("/assets/", http.FileServer(http.FS(assets.Assets)))))

	http.ListenAndServe(":8080", mux)
}

func disableCacheInDevMode(next http.Handler) http.Handler {
	devEnv, _ := os.LookupEnv("ENVIRONMENT")
	if devEnv != "dev" {
		return next
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		next.ServeHTTP(w, r)
	})
}
