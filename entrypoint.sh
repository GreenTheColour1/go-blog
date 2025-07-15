# Run database migrations
migrate -source file://database/migrations -database "$POSTGRES_URL" up

# Run main binary
exec ./bin/blog "$@"

