templ: templ generate --watch --proxy="http://localhost:8080" --open-browser=false
server: air --build.cmd "go build -o tmp/bin/main ./cmd/blog/main.go" --build.bin "tmp/bin/main" --build.delay "100" --build.exclude_dir "node_modules,pgdata" --build.include_ext "go" --build.stop_on_error "false" --misc.clean_on_exit true
tailwind: tailwindcss -i ./assets/css/input.css -o ./assets/css/output.css --watch
