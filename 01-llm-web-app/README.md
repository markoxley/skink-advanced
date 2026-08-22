# LLM Web Application

A complete full-stack application demonstrating Skink's LLM capabilities, networking, and JSON API handling. It serves a chat web frontend, exposes a JSON chat API, and logs requests to a file. Without a GGUF model it runs in demo mode with rule-based responses.

## Project Overview

- **Local LLM Inference**: Uses `std/llm` to load GGUF models when available
- **HTTP Server**: Uses `std/net` for TCP listening and connection handling
- **Static Files**: Serves `static/index.html` and related assets
- **Request Logging**: Writes chat prompts and responses to `app.log`
- **Demo Mode**: Falls back to keyword-based answers when no model is found

## Project Structure

```
01-llm-web-app/
├── README.md
├── code/
│   ├── main.skink          # Server and handlers
│   └── static/
│       └── index.html      # Web frontend
```

## Build and Run

```bash
skink code/main.skink
./code/main
```

The server listens on `http://127.0.0.1:8080`.

## Endpoints

- `GET /` – serves `static/index.html`
- `GET /static/*` – serves static files
- `GET /health` – returns `{"status":"ok"}`
- `POST /api/chat` – accepts `{"prompt":"..."}` and returns `{"response":"..."}`

## Model Setup

Place a GGUF model at one of these locations to enable real LLM inference:

- `code/models/model.gguf`
- `code/model.gguf`
- `code/data/model.gguf`

If no model is found, the app prints a message and runs in demo mode.

## Key Skink Features Demonstrated

- `std/llm` for local model loading and text generation
- `std/net` for TCP listening and connection handling
- `std/json` for JSON parsing and serialization
- `std/fs` for file reading and logging
- Global state, error handling, and struct method calls
