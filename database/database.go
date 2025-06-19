package database

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"fmt"
	"io/fs"
	"log"
	"strings"
	"time"

	"github.com/GreenTheColour1/go-blog/posts"
	_ "github.com/lib/pq"
)

type Database struct {
	DB  *sql.DB
	ctx context.Context
}

const (
	host     = "localhost"
	port     = 5432
	user     = "fishy"
	password = ""
	dbname   = "postgres"
)

func Connect() Database {
	pgsqlconn := fmt.Sprintf("user=%s dbname=%s host=/tmp sslmode=disable", user, dbname)
	db, err := sql.Open("postgres", pgsqlconn)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Connected")

	ctx := context.Background()

	createPostsTable(ctx, db)
	err = loadMarkdownFiles(ctx, db)
	if err != nil {
		log.Fatal(err)
	}

	return Database{db, ctx}
}

func (db Database) GetPostBySlug(slug string) (*posts.Post, error) {
	post := new(posts.Post)
	if err := db.DB.QueryRowContext(db.ctx, `SELECT filename, title FROM posts WHERE slug = $1`, slug).Scan(&post.Filename, &post.Title); err != nil {
		return nil, fmt.Errorf("Failed to get post: %w", err)
	}

	body, err := posts.PostAssets.ReadFile(post.Filename)
	if err != nil {
		return nil, fmt.Errorf("Failed to read file %s: %w", post.Filename, err)
	}

	post.Body = string(body)

	return post, nil
}

func (db Database) GetAllPosts() ([]posts.Post, error) {
	result, err := db.DB.QueryContext(db.ctx, `SELECT created_at, title, slug FROM posts`)
	if err != nil {
		return nil, fmt.Errorf("Failed to get posts: %w", err)
	}
	defer result.Close()

	var p posts.Post
	var posts []posts.Post

	for result.Next() {
		if err := result.Scan(&p.Created_at, &p.Title, &p.Slug); err != nil {
			return nil, fmt.Errorf("Failed to scan posts: %w", err)
		}
		posts = append(posts, p)
	}

	return posts, nil
}

func createPostsTable(ctx context.Context, db *sql.DB) error {
	_, err := db.ExecContext(ctx, `
		CREATE TABLE IF NOT EXISTS posts (
			id uuid primary key,
			created_at timestamp not null,
			updated_at timestamp not null,
			title varchar(255) not null,
			filename varchar(255) not null,
			slug varchar(255) not null,
			hash bytea not null
		)
		`)
	if err != nil {
		return fmt.Errorf("Failed to create table posts: %w", err)
	}

	return nil
}

func loadMarkdownFiles(ctx context.Context, db *sql.DB) error {
	files, err := fs.Glob(posts.PostAssets, "files/*.md")
	if err != nil {
		return fmt.Errorf("Failed to list embedded markdown files: %w", err)
	}
	log.Printf("Found %d markdown files", len(files))

	// Track files
	embeddedFiles := make(map[string]bool)

	for _, file := range files {
		embeddedFiles[file] = true

		content, err := posts.PostAssets.ReadFile(file)
		if err != nil {
			return fmt.Errorf("Failed to read embedded file %s: %w", file, err)
		}

		title := strings.TrimSuffix(file[6:], ".md")
		slug := strings.ToLower(strings.ReplaceAll(title, " ", "-"))
		hash := sha256.Sum256(content)
		now := time.Now()

		// Check if entry exists
		var existingHash []byte

		err = db.QueryRowContext(ctx, `
			SELECT hash
			FROM posts
			WHERE filename = $1
			`, file).Scan(&existingHash)

		switch {
		case err == sql.ErrNoRows:
			//Insert new record
			_, err := db.ExecContext(ctx, `
				INSERT INTO posts (id, created_at, updated_at, title, filename, slug, hash)
				VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6)
				`, now, now, title, file, slug, hash[:])
			if err != nil {
				return fmt.Errorf("Query error for %s: %w", file, err)
			}
		case err != nil:
			return fmt.Errorf("Update error for %s: %w", file, err)
		default:
			//Update if hash is different
			if !compareHashes(existingHash, hash[:]) {
				_, err := db.ExecContext(ctx, `
					UPDATE posts
					SET updated_at = $1, title = $2, slug = $3, hash = $4
					WHERE filename = $5
					`, now, title, slug, hash[:], file)
				if err != nil {
					return fmt.Errorf("Update error for %s: %w", file, err)
				}
			}
		}
	}

	// Delete rows that have no corrosponding file
	rows, err := db.QueryContext(ctx, `SELECT filename FROM posts`)
	if err != nil {
		return fmt.Errorf("Failed to query filenames: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var dbFile string
		if err := rows.Scan(&dbFile); err != nil {
			return fmt.Errorf("Failed to scan filename: %w", err)
		}

		if !embeddedFiles[dbFile] {
			_, err := db.ExecContext(ctx, `DELETE FROM posts WHERE filename = $1`, dbFile)
			if err != nil {
				return fmt.Errorf("Failed to delete %s: %w", dbFile, err)
			}
		}
	}
	return nil
}

func compareHashes(a, b []byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
