# LLM Web Application with Middleware Logging

A complete full-stack application demonstrating Skink's LLM capabilities, web framework, and file I/O. This project includes a web frontend, middleware server, and request logging to showcase real-world AI application development.

## Project Overview

This application provides a web interface for interacting with local LLM models. It demonstrates:

- **Local LLM Inference**: Using `std/llm` to run GGUF models without cloud dependencies
- **Web Framework**: Using Skink's built-in web framework for HTTP server
- **Middleware Pattern**: Request/response middleware for logging and validation
- **File Logging**: Persistent logging of all LLM requests and responses
- **Concurrency**: Handling multiple concurrent chat sessions

## Architecture

```
┌─────────────┐     HTTP      ┌──────────────┐     LLM     ┌─────────────┐
│   Browser   │ ────────────> │  Middleware  │ ──────────> │  LLM Model  │
│  (Frontend) │               │   Server     │             │  (GGUF)     │
└─────────────┘               └──────────────┘             └─────────────┘
                                      │
                                      │ Logs
                                      ▼
                              ┌───────────────┐
                              │  requests.log │
                              └───────────────┘
```

## Project Structure

```
01-llm-web-app/
├── README.md
├── main.skink          # Main server entry point
├── middleware.skink    # Request logging middleware
├── llm_handler.skink   # LLM inference logic
├── logger.skink        # File logging utilities
├── static/
│   └── index.html      # Simple web frontend
└── data/
    └── requests.log    # Request log file
```

## Implementation

### 1. Logger Module (`logger.skink`)

Handles file-based logging with thread-safe operations.

```skink
import "std/fs"
import "std/time"
import "std/sync"

struct Logger {
    file: fs.File
    mutex: sync.Mutex
}

fn NewLogger(path: string) -> (Logger, error) {
    file, err := fs.OpenFile(path, fs.O_CREATE | fs.O_WRONLY | fs.O_APPEND, 0644)
    if err != nil {
        return Logger{}, err
    }
    return Logger{file: file, mutex: sync.Mutex{}}, nil
}

fn (l: *Logger) Log(message: string) {
    l.mutex.Lock()
    defer l.mutex.Unlock()
    
    timestamp := time.Now().Format("2006-01-02 15:04:05")
    logLine := "[{timestamp}] {message}\n"
    l.file.WriteString(logLine)
}

fn (l: *Logger) Close() {
    l.file.Close()
}
```

### 2. Middleware Module (`middleware.skink`)

HTTP middleware for logging all requests and responses.

```skink
import "std/web"
import "logger"

struct LoggingMiddleware {
    logger: Logger
}

fn NewLoggingMiddleware(logger: Logger) -> LoggingMiddleware {
    return LoggingMiddleware{logger: logger}
}

fn (m: *LoggingMiddleware) Process(req: web.Request, next: web.Handler) -> web.Response {
    // Log incoming request
    m.logger.Log("Request: {req.Method} {req.Path} from {req.RemoteAddr}")
    
    // Process request
    response := next(req)
    
    // Log response
    m.logger.Log("Response: {response.Status} in {response.Duration}ms")
    
    return response
}
```

### 3. LLM Handler Module (`llm_handler.skink`)

Handles LLM model loading and text generation.

```skink
import "std/llm"
import "std/errors"

struct LLMHandler {
    ctx: llm.Context
}

fn NewLLMHandler(modelPath: string, contextSize: int) -> (LLMHandler, error) {
    ctx, err := llm.LoadModel(modelPath, contextSize)
    if err != nil {
        return LLMHandler{}, err
    }
    return LLMHandler{ctx: ctx}, nil
}

fn (h: *LLMHandler) Generate(prompt: string, maxTokens: int) -> (string, error) {
    output, err := h.ctx.Generate(prompt, maxTokens)
    if err != nil {
        return "", err
    }
    return output, nil
}

fn (h: *LLMHandler) Close() {
    h.ctx.Close()
}
```

### 4. Main Server (`main.skink`)

Main application server integrating all components.

```skink
import "std/web"
import "std/fs"
import "logger"
import "middleware"
import "llm_handler"

fn main() -> int {
    // Initialize logger
    log, err := logger.NewLogger("data/requests.log")
    if err != nil {
        print("Failed to create logger: {err.message}")
        return 1
    }
    defer log.Close()
    
    // Initialize LLM handler
    llmHandler, err := llm_handler.NewLLMHandler("models/llama-2-7b.Q4_K_M.gguf", 4096)
    if err != nil {
        print("Failed to load LLM: {err.message}")
        return 1
    }
    defer llmHandler.Close()
    
    // Create web server
    server := web.NewServer(":8080")
    
    // Add logging middleware
    loggingMW := middleware.NewLoggingMiddleware(log)
    server.Use(loggingMW.Process)
    
    // Serve static files
    server.Static("/static", "static")
    
    // Chat endpoint
    server.Post("/api/chat", fn(req: web.Request) -> web.Response {
        // Parse request body
        body := req.Body()
        prompt := body.Get("prompt")
        
        if prompt == "" {
            return web.JSON(400, map{"error": "Prompt is required"})
        }
        
        // Generate response
        response, err := llmHandler.Generate(prompt, 200)
        if err != nil {
            log.Log("LLM Error: {err.message}")
            return web.JSON(500, map{"error": err.message})
        }
        
        // Log the interaction
        log.Log("Chat: prompt='{prompt}' response_length={len(response)}")
        
        return web.JSON(200, map{
            "response": response,
            "tokens": len(response)
        })
    })
    
    // Health check
    server.Get("/health", fn(req: web.Request) -> web.Response {
        return web.JSON(200, map{"status": "ok", "model": "llama-2-7b"})
    })
    
    print("Server starting on :8080")
    server.Run()
    
    return 0
}
```

### 5. Web Frontend (`static/index.html`)

Simple HTML/JS frontend for the chat interface.

```html
<!DOCTYPE html>
<html>
<head>
    <title>Skink LLM Chat</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        #chat { border: 1px solid #ccc; padding: 20px; height: 400px; overflow-y: scroll; margin-bottom: 20px; }
        .message { margin: 10px 0; padding: 10px; border-radius: 5px; }
        .user { background: #e3f2fd; text-align: right; }
        .assistant { background: #f5f5f5; }
        input { width: 70%; padding: 10px; }
        button { padding: 10px 20px; }
    </style>
</head>
<body>
    <h1>Skink LLM Chat</h1>
    <div id="chat"></div>
    <input type="text" id="prompt" placeholder="Enter your message...">
    <button onclick="send()">Send</button>
    
    <script>
        async function send() {
            const prompt = document.getElementById('prompt').value;
            const chat = document.getElementById('chat');
            
            chat.innerHTML += `<div class="message user">${prompt}</div>`;
            document.getElementById('prompt').value = '';
            
            const response = await fetch('/api/chat', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({prompt})
            });
            
            const data = await response.json();
            chat.innerHTML += `<div class="message assistant">${data.response}</div>`;
            chat.scrollTop = chat.scrollHeight;
        }
    </script>
</body>
</html>
```

## Setup Instructions

1. **Install Dependencies**
   ```bash
   # Install llama.cpp libraries
   # See skink manual for platform-specific instructions
   ```

2. **Download Model**
   ```bash
   mkdir models
   # Download a GGUF model, e.g., Llama 2 7B Q4
   wget https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_K_M.gguf
   ```

3. **Create Data Directory**
   ```bash
   mkdir data
   ```

4. **Build and Run**
   ```bash
   skink build main.skink
   ./main
   ```

5. **Access the Application**
   - Open browser to `http://localhost:8080/static/index.html`
   - Send messages to interact with the LLM
   - Check `data/requests.log` for request logs

## Key Skink Features Demonstrated

- **`std/llm`**: Local LLM inference without cloud APIs
- **`std/web`**: Built-in HTTP server and routing
- **`std/fs`**: File I/O for logging
- **`std/sync`**: Mutex for thread-safe logging
- **Middleware Pattern**: Request/response processing pipeline
- **Error Handling**: Explicit error propagation
- **Resource Management**: `defer` for cleanup

## Extending the Project

- Add user authentication
- Implement conversation history with `std/db` (SQLite)
- Add streaming responses for real-time generation
- Implement rate limiting
- Add model switching support
- Create admin dashboard for log viewing
