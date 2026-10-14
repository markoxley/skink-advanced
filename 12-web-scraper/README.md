# 12. CLI Web Scraper

A real command-line web scraper — unlike the simulated fetch in
`05-concurrent-scraper`, this one makes live HTTP requests, extracts
matches with POSIX regex, and optionally persists hits to SQLite via
`std/orm`.

## What it demonstrates

- **`std/api` HTTP client** — `api.Get` over HTTP/HTTPS with status
  checking
- **`std/regex` extraction** — POSIX ERE `FindAll` over the page body
- **`std/orm` persistence** — `--save` writes hits through the same
  tag-driven table machinery as the REST API (a second, independent
  orm consumer)
- **CLI conventions** — `os.Args()` parsing, usage text, exit codes,
  `io.PrintErrorLine` diagnostics on stderr
- **In-process live testing** — `scraper_test.skink` spawns a real
  `std/web` server, fetches it over real TCP, and asserts extraction
  plus sqlite persistence end-to-end

## Usage

```sh
cd code
skink -o scrape main.skink

./scrape "https://example.com" 'href="[^"]+"'
./scrape "https://example.com" '<h[0-9][^>]*>[^<]+' --save hits.db
```

Output: one match per line, then a match count; `--save` also writes
`(id, url, text)` rows into a `hits` table in the named SQLite file.

## Layout

```
code/
  main.skink          — CLI: arg parsing, usage, exit codes
  scraper.skink       — FetchURL / Extract / SaveHits core
  scraper_test.skink  — live end-to-end test (spawned fixture server)
```

## Tests

```sh
cd code
skink -t scraper_test.skink
```

Three tests: the live fetch→extract→save roundtrip against a spawned
`std/web` fixture, invalid-regex error handling, and unreachable-URL
error handling.
