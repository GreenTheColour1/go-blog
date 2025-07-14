This is a test file to test the formatting to the markdown -> html conversion
<br/>

# This is a heading lvl
<br/>

## This is a heading lvl 2
<br/>

## This is a heading lvl 3
<br/>

[This](https://blog.camerongreen.ca) is a link
<br/>

This is a table
|Col 1 | Col 2 |
|------|-------|
| item1 | item2 |

<br/>

This is a code block
```go
func (p *Post) ConvertBodyToHTML() {
	var buf bytes.Buffer

	if err := goldmark.Convert(p.Body, &buf); err != nil {
		panic(err)
	}

	p.RawHTML = buf.String()
}

```

