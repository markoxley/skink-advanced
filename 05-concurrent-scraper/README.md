# Concurrent Web Scraper with Worker Pools

A high-performance web scraper demonstrating Skink's concurrency model, worker pools, and HTTP client capabilities. This project scrapes multiple websites concurrently using goroutines and channels.

## Project Overview

This project implements a concurrent web scraper that:
- Fetches multiple URLs in parallel using worker pools
- Extracts data from HTML responses
- Handles rate limiting and timeouts
- Saves results to CSV and JSON formats
- Demonstrates Skink's concurrency primitives (goroutines, channels, waitgroups)

## Architecture

```
┌─────────────┐    URLs     ┌─────────────┐   Fetch    ┌─────────────┐
│   Input     │ ──────────> │  URL Queue  │ ─────────> │  Workers    │
│  (File/CLI) │             └─────────────┘            └─────────────┘
                                                              │
                                                              ▼
┌─────────────┐   Results  ┌─────────────┐    Parse   ┌─────────────┐
│   Output    │ <───────── │  Result     │ <───────── │  Parser     │
│  (CSV/JSON) │            │  Channel    │            └─────────────┘
└─────────────┘            └─────────────┘
```

## Project Structure

```
05-concurrent-scraper/
├── README.md
├── main.skink          # Main scraper entry point
├── worker.skink        # Worker pool implementation
├── scraper.skink       # HTTP client and scraping logic
├── parser.skink        # HTML parsing and data extraction
├── output.skink        # Result formatting and file output
├── urls.txt            # List of URLs to scrape
└── output/
    ├── results.csv     # CSV output
    └── results.json    # JSON output
```

## Implementation

### 1. Worker Pool Module (`worker.skink`)

Implements a concurrent worker pool with channels.

```skink
import "std/sync"

struct Task {
    url: string
    id: int
}

struct Result {
    url: string
    status: int
    title: string
    content: string
    error: string
    duration: int
}

struct WorkerPool {
    tasks: chan<Task>
    results: chan<Result>
    workers: int
    wg: sync.WaitGroup
}

fn NewWorkerPool(numWorkers: int, taskQueueSize: int) -> WorkerPool {
    return WorkerPool{
        tasks: make(chan<Task>, taskQueueSize),
        results: make(chan<Result>, taskQueueSize),
        workers: numWorkers,
        wg: sync.WaitGroup{}
    }
}

fn (p: *WorkerPool) Start(handler: fn(Task) -> Result) {
    for i := 0; i < p.workers; i = i + 1 {
        p.wg.Add(1)
        spawn fn(p: *WorkerPool, handler: fn(Task) -> Result, workerId: int) {
            defer p.wg.Done()
            
            for task := range p.tasks {
                result := handler(task)
                p.results <- result
            }
        }(p, handler, i)
    }
}

fn (p: *WorkerPool) Submit(task: Task) {
    p.tasks <- task
}

fn (p: *WorkerPool) Close() {
    close(p.tasks)
}

fn (p: *WorkerPool) Wait() {
    p.wg.Wait()
    close(p.results)
}

fn (p: *WorkerPool) Results() -> chan<Result> {
    return p.results
}
```

### 2. Scraper Module (`scraper.skink`)

HTTP client with rate limiting and error handling.

```skink
import "std/net"
import "std/time"
import "std/errors"

struct ScraperConfig {
    timeout: int
    userAgent: string
    maxRetries: int
    retryDelay: int
}

struct Scraper {
    client: net.Client
    config: ScraperConfig
    rateLimiter: chan<bool>
}

fn NewScraper(config: ScraperConfig, maxConcurrent: int) -> Scraper {
    client := net.Client{
        Timeout: time.Duration(config.timeout) * time.Millisecond
    }
    
    return Scraper{
        client: client,
        config: config,
        rateLimiter: make(chan<bool>, maxConcurrent)
    }
}

fn (s: *Scraper) Fetch(url: string) -> (int, string, error) {
    // Rate limiting
    s.rateLimiter <- true
    defer func() { <-s.rateLimiter }()
    
    startTime := time.Now()
    
    // Create request
    req := net.Request{
        Method: "GET",
        URL: url,
        Headers: map[string]string{
            "User-Agent": s.config.userAgent
        }
    }
    
    // Execute with retries
    for attempt := 0; attempt < s.config.maxRetries; attempt = attempt + 1 {
        resp, err := s.client.Do(&req)
        if err != nil {
            if attempt < s.config.maxRetries - 1 {
                time.Sleep(time.Duration(s.config.retryDelay) * time.Millisecond)
                continue
            }
            return 0, "", err
        }
        
        body, err := resp.Body()
        if err != nil {
            return resp.StatusCode, "", err
        }
        
        return resp.StatusCode, body, nil
    }
    
    return 0, "", errors.New("max retries exceeded")
}

fn (s: *Scraper) FetchWithTiming(url: string) -> (int, string, int, error) {
    startTime := time.Now()
    status, body, err := s.Fetch(url)
    duration := time.Since(startTime).Milliseconds()
    
    return status, body, duration, err
}
```

### 3. Parser Module (`parser.skink`)

HTML parsing and data extraction.

```skink
import "std/str"
import "std/regex"

struct ParsedData {
    title: string
    description: string
    links: []string
    headings: []string
}

fn ParseHTML(html: string) -> ParsedData {
    data := ParsedData{}
    
    // Extract title
    titleRegex := regex.MustCompile("<title>(.*?)</title>", regex.CASE_INSENSITIVE)
    titleMatch := titleRegex.FindStringSubmatch(html)
    if len(titleMatch) > 1 {
        data.title = titleMatch[1]
    }
    
    // Extract meta description
    descRegex := regex.MustCompile("<meta name=\"description\" content=\"(.*?)\">", regex.CASE_INSENSITIVE)
    descMatch := descRegex.FindStringSubmatch(html)
    if len(descMatch) > 1 {
        data.description = descMatch[1]
    }
    
    // Extract links
    linkRegex := regex.MustCompile("<a href=\"(.*?)\"", regex.CASE_INSENSITIVE)
    linkMatches := linkRegex.FindAllStringSubmatch(html, -1)
    for i := 0; i < len(linkMatches); i = i + 1 {
        if len(linkMatches[i]) > 1 {
            data.links = append(data.links, linkMatches[i][1])
        }
    }
    
    // Extract headings
    headingRegex := regex.MustCompile("<h[1-6]>(.*?)</h[1-6]>", regex.CASE_INSENSITIVE)
    headingMatches := headingRegex.FindAllStringSubmatch(html, -1)
    for i := 0; i < len(headingMatches); i = i + 1 {
        if len(headingMatches[i]) > 1 {
            data.headings = append(data.headings, headingMatches[i][1])
        }
    }
    
    return data
}

fn CleanText(text: string) -> string {
    // Remove HTML tags
    clean := regex.MustCompile("<[^>]*>").ReplaceAllString(text, "")
    // Decode HTML entities
    clean = str.Replace(clean, "&amp;", "&")
    clean = str.Replace(clean, "&lt;", "<")
    clean = str.Replace(clean, "&gt;", ">")
    clean = str.Replace(clean, "&quot;", "\"")
    // Trim whitespace
    clean = str.TrimSpace(clean)
    
    return clean
}
```

### 4. Output Module (`output.skink`)

Formats and saves results to CSV and JSON.

```skink
import "std/fs"
import "std/str"
import "worker"

struct OutputConfig {
    csvPath: string
    jsonPath: string
}

fn SaveCSV(results: []worker.Result, path: string) -> error {
    file, err := fs.Create(path)
    if err != nil {
        return err
    }
    defer file.Close()
    
    // Write header
    header := "URL,Status,Title,Error,Duration(ms)\n"
    file.WriteString(header)
    
    // Write rows
    for i := 0; i < len(results); i = i + 1 {
        r := results[i]
        line := "{r.url},{r.status},\"{r.title}\",\"{r.error}\",{r.duration}\n"
        file.WriteString(line)
    }
    
    return nil
}

fn SaveJSON(results: []worker.Result, path: string) -> error {
    file, err := fs.Create(path)
    if err != nil {
        return err
    }
    defer file.Close()
    
    // Build JSON array
    json := "[\n"
    for i := 0; i < len(results); i = i + 1 {
        r := results[i]
        if i > 0 {
            json += ",\n"
        }
        json += "  {\n"
        json += "    \"url\": \"{r.url}\",\n"
        json += "    \"status\": {r.status},\n"
        json += "    \"title\": \"{r.title}\",\n"
        json += "    \"error\": \"{r.error}\",\n"
        json += "    \"duration\": {r.duration}\n"
        json += "  }"
    }
    json += "\n]\n"
    
    file.WriteString(json)
    return nil
}

fn PrintSummary(results: []worker.Result) {
    total := len(results)
    success := 0
    failed := 0
    totalDuration := 0
    
    for i := 0; i < len(results); i = i + 1 {
        r := results[i]
        totalDuration = totalDuration + r.duration
        if r.status >= 200 && r.status < 300 {
            success = success + 1
        } else {
            failed = failed + 1
        }
    }
    
    print("\n=== Scraping Summary ===")
    print("Total URLs: {total}")
    print("Successful: {success}")
    print("Failed: {failed}")
    print("Success rate: {float(success) / float(total) * 100.0}%")
    print("Total time: {totalDuration}ms")
    print("Average time: {totalDuration / total}ms")
}
```

### 5. Main Application (`main.skink`)

Main scraper orchestrating all components.

```skink
import "std/fs"
import "std/str"
import "worker"
import "scraper"
import "parser"
import "output"

fn main() -> int {
    print("Starting Concurrent Web Scraper...")
    
    // Configuration
    numWorkers := 10
    maxConcurrent := 5
    timeout := 10000 // 10 seconds
    maxRetries := 3
    retryDelay := 1000 // 1 second
    
    // Initialize scraper
    scraperConfig := scraper.ScraperConfig{
        timeout: timeout,
        userAgent: "Skink-Scraper/1.0",
        maxRetries: maxRetries,
        retryDelay: retryDelay
    }
    
    scraper := scraper.NewScraper(scraperConfig, maxConcurrent)
    
    // Load URLs from file or use defaults
    urls := []string{
        "https://example.com",
        "https://httpbin.org/html",
        "https://httpbin.org/json",
        "https://httpbin.org/headers",
        "https://httpbin.org/user-agent"
    }
    
    // Check for URLs file
    if fs.Exists("urls.txt") {
        content, err := fs.ReadFile("urls.txt")
        if err == nil {
            lines := str.Split(content, "\n")
            urls = []string{}
            for i := 0; i < len(lines); i = i + 1 {
                line := str.TrimSpace(lines[i])
                if line != "" && !str.HasPrefix(line, "#") {
                    urls = append(urls, line)
                }
            }
        }
    }
    
    print("Loaded {len(urls)} URLs to scrape")
    print("Using {numWorkers} workers")
    
    // Create worker pool
    pool := worker.NewWorkerPool(numWorkers, len(urls))
    
    // Define task handler
    handler := fn(task: worker.Task) -> worker.Result {
        print("Fetching: {task.url}")
        
        status, body, duration, err := scraper.FetchWithTiming(task.url)
        
        result := worker.Result{
            url: task.url,
            status: status,
            duration: duration
        }
        
        if err != nil {
            result.error = err.message
            print("Error fetching {task.url}: {err.message}")
            return result
        }
        
        // Parse HTML
        parsed := parser.ParseHTML(body)
        result.title = parser.CleanText(parsed.title)
        result.content = parser.CleanText(parsed.description)
        
        print("Fetched {task.url}: {status} - {result.title}")
        return result
    }
    
    // Start workers
    pool.Start(handler)
    
    // Submit tasks
    for i := 0; i < len(urls); i = i + 1 {
        task := worker.Task{
            url: urls[i],
            id: i
        }
        pool.Submit(task)
    }
    
    // Close task queue and wait for completion
    pool.Close()
    pool.Wait()
    
    // Collect results
    results := []worker.Result{}
    for result := range pool.Results() {
        results = append(results, result)
    }
    
    // Create output directory
    fs.MkdirAll("output", 0755)
    
    // Save results
    print("\nSaving results...")
    err := output.SaveCSV(results, "output/results.csv")
    if err != nil {
        print("Error saving CSV: {err.message}")
    }
    
    err = output.SaveJSON(results, "output/results.json")
    if err != nil {
        print("Error saving JSON: {err.message}")
    }
    
    // Print summary
    output.PrintSummary(results)
    
    print("\nScraping complete!")
    return 0
}
```

### 6. Sample URLs File (`urls.txt`)

List of URLs to scrape.

```
# Web Scraper URLs
# One URL per line, lines starting with # are comments

https://example.com
https://httpbin.org/html
https://httpbin.org/json
https://httpbin.org/headers
https://httpbin.org/user-agent
https://httpbin.org/delay/1
https://httpbin.org/status/200
https://httpbin.org/status/404
https://httpbin.org/status/500
```

## Setup Instructions

1. **Create Output Directory**
   ```bash
   mkdir output
   ```

2. **Create URLs File**
   - Create `urls.txt` with URLs to scrape (one per line)
   - Or use the default URLs in the code

3. **Build and Run**
   ```bash
   skink build main.skink
   ./main
   ```

## Expected Output

```
Starting Concurrent Web Scraper...
Loaded 9 URLs to scrape
Using 10 workers
Fetching: https://example.com
Fetching: https://httpbin.org/html
Fetching: https://httpbin.org/json
...
Fetched https://example.com: 200 - Example Domain
Fetched https://httpbin.org/html: 200 - 

Saving results...

=== Scraping Summary ===
Total URLs: 9
Successful: 8
Failed: 1
Success rate: 88.89%
Total time: 5234ms
Average time: 581ms

Scraping complete!
```

## Output Files

### CSV Output (`output/results.csv`)
```csv
URL,Status,Title,Error,Duration(ms)
https://example.com,200,"Example Domain","",234
https://httpbin.org/html,200,"","",156
...
```

### JSON Output (`output/results.json`)
```json
[
  {
    "url": "https://example.com",
    "status": 200,
    "title": "Example Domain",
    "error": "",
    "duration": 234
  },
  ...
]
```

## Key Skink Features Demonstrated

- **Goroutines**: Concurrent execution with `spawn`
- **Channels**: Communication between goroutines
- **WaitGroups**: Synchronization for concurrent tasks
- **Worker Pools**: Pattern for managing concurrent work
- **`std/net`**: HTTP client for web requests
- **`std/regex`**: Regular expressions for parsing
- **`std/str`**: String manipulation
- **`std/fs`**: File I/O for saving results
- **Error Handling**: Explicit error propagation
- **Rate Limiting**: Channel-based throttling
- **Resource Management**: `defer` for cleanup

## Extending the Project

- Add proxy support
- Implement JavaScript rendering with headless browser
- Add authentication (cookies, API keys)
- Implement sitemap parsing
- Add robots.txt compliance
- Implement deduplication
- Add support for different output formats (XML, SQLite)
- Implement progress tracking and resumption
- Add web scraping API
- Implement distributed scraping across multiple machines
- Add machine learning for content classification
