package assets

import "embed"

//go:embed css/*.css js/*.js
var Assets embed.FS
