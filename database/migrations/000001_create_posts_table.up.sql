CREATE TABLE IF NOT EXISTS posts (
  id uuid primary key,
  created_at timestamp not null,
  updated_at timestamp not null,
  title varchar(255) not null,
  filename varchar(255) not null,
  slug varchar(255) not null,
  hash bytea not null
)
