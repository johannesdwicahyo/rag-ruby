# rag-ruby

A batteries-included RAG (Retrieval-Augmented Generation) pipeline framework for Ruby and Rails.

Orchestrates the full workflow: **document loading → chunking → embedding → storage → retrieval → generation**. Think LangChain for Ruby — simpler, more opinionated, and Rails-native.

## Installation

Add to your Gemfile:

```ruby
gem "rag-ruby"
```

Then run:

```bash
bundle install
```

## Quick Start

```ruby
require "rag_ruby"

pipeline = RagRuby::Pipeline.new do |config|
  config.loader :file
  config.chunker :recursive_character, chunk_size: 1000, chunk_overlap: 200
  config.embedder :openai, model: "text-embedding-3-small"
  config.store :memory, dimension: 1536
  config.generator :openai, model: "gpt-4o"
end

# Ingest documents
pipeline.ingest("docs/manual.md")
pipeline.ingest_directory("docs/", glob: "**/*.{md,txt}")

# Query with RAG
answer = pipeline.query("How do I reset my password?")
answer.text       # => "To reset your password, go to Settings > Security..."
answer.sources    # => [#<Source chunk="..." score=0.92>, ...]
answer.tokens_used # => { prompt: 1200, completion: 150 }
```

## Components

Every stage of the pipeline is pluggable. Mix and match providers to fit your stack.

### Document Loaders

| Loader | Description | Require |
|--------|-------------|---------|
| `:file` | Local files (.txt, .md) | Built-in |
| `:directory` | Bulk load from directory | Built-in |
| `:url` | Fetch from URLs | Built-in |
| `:active_record` | Load from ActiveRecord models | Built-in |

```ruby
# Load a single file
pipeline.ingest("path/to/document.md")

# Load a directory
pipeline.ingest_directory("documents/", glob: "**/*.{md,txt}")

# Custom loader
class SlackLoader < RagRuby::Loaders::Base
  def load(channel_id)
    messages = SlackAPI.history(channel_id)
    messages.map do |msg|
      RagRuby::Document.new(
        content: msg.text,
        metadata: { author: msg.user, channel: channel_id }
      )
    end
  end
end

pipeline.ingest(channel_id, loader: SlackLoader.new)
```

### Embedders

| Provider | Description | Require |
|----------|-------------|---------|
| `:openai` | OpenAI text-embedding-3-small/large | `OPENAI_API_KEY` env var |
| `:cohere` | Cohere embed-english-v3.0 | `COHERE_API_KEY` env var |
| `:onnx` | Local ONNX models (all-MiniLM-L6-v2) | `gem "onnx-ruby"` |

```ruby
# API-based
config.embedder :openai, model: "text-embedding-3-small"
config.embedder :cohere, model: "embed-english-v3.0"

# Local (no API calls)
config.embedder :onnx, model: "all-MiniLM-L6-v2"
```

### Vector Stores

| Store | Description | Require |
|-------|-------------|---------|
| `:memory` | In-memory store (great for dev/test) | Built-in |
| `:zvec` | Persistent file-based vector store | `gem "zvec-ruby"` |

```ruby
config.store :memory, dimension: 1536
config.store :zvec, path: "./vectors", dimension: 1536
```

Custom stores are easy — implement `add`, `search`, `delete`, and `count`:

```ruby
class PineconeStore < RagRuby::Stores::Base
  def add(id, embedding:, metadata: {}, chunk: nil) = ...
  def search(embedding, top_k:, filter: nil) = ...
  def delete(id) = ...
  def count = ...
end
```

### Generators

| Provider | Description | Require |
|----------|-------------|---------|
| `:openai` | OpenAI chat completions | `OPENAI_API_KEY` env var |
| `:ruby_llm` | Any model via ruby_llm | `gem "ruby_llm"` |

```ruby
config.generator :openai, model: "gpt-4o"
config.generator :ruby_llm, model: "claude-sonnet-4-20250514"
```

## Query Options

```ruby
answer = pipeline.query("What changed in v2.0?",
  top_k: 10,                    # number of chunks to retrieve
  filter: { category: "changelog" }, # metadata filter
  temperature: 0.0,             # generation temperature
  system_prompt: "You are a technical docs assistant."
)

answer.text        # generated answer
answer.sources     # retrieved chunks with scores
answer.tokens_used # { prompt: ..., completion: ... }
answer.duration    # query time in seconds
answer.query       # original question
```

## Callbacks & Observability

Hook into every stage of the pipeline for logging, metrics, or debugging:

```ruby
pipeline = RagRuby::Pipeline.new do |config|
  # ... providers ...

  config.on(:before_load)  { |src| puts "Loading: #{src}" }
  config.on(:after_load)   { |docs| puts "Loaded #{docs.size} documents" }
  config.on(:before_chunk) { |doc| puts "Chunking: #{doc.source}" }
  config.on(:after_chunk)  { |chunks| puts "Created #{chunks.size} chunks" }
  config.on(:before_embed) { |chunks| puts "Embedding #{chunks.size} chunks" }
  config.on(:after_embed)  { |chunks| puts "Embedded #{chunks.size} chunks" }
  config.on(:before_store) { |chunks| puts "Storing #{chunks.size} chunks" }
  config.on(:after_store)  { |chunks| puts "Stored #{chunks.size} chunks" }
  config.on(:before_query) { |q| Metrics.increment("rag.queries") }
  config.on(:after_query)  { |q, answer| Metrics.timing("rag.latency", answer.duration) }
end
```

## Rails Integration

### Setup

```bash
rails generate rag:install
```

This creates:
- `config/rag.yml` — environment-specific configuration
- `config/initializers/rag_ruby.rb` — optional programmatic config

### Configuration

```yaml
# config/rag.yml
default: &default
  chunker:
    strategy: recursive_character
    chunk_size: 1000
    chunk_overlap: 200
  embedder:
    provider: openai
    model: text-embedding-3-small
  store:
    provider: memory
    dimension: 1536
  generator:
    provider: openai
    model: gpt-4o

development:
  <<: *default

production:
  <<: *default
  store:
    provider: zvec
    path: db/vectors
    dimension: 1536
```

### Auto-Index Models

```ruby
class Article < ApplicationRecord
  include RagRuby::Indexable

  rag_index :content,
    metadata: ->(article) { { category: article.category, author: article.author } },
    on: [:create, :update]
end

# Articles are automatically indexed when saved
Article.create!(title: "Guide", content: "# Getting Started\n...")
```

### Global API

```ruby
# Search for relevant chunks
results = RagRuby.search("How to get started?", top_k: 5)

# Full RAG: retrieve + generate
answer = RagRuby.ask("How to get started?")
```

### Controller Usage

```ruby
class ChatController < ApplicationController
  def ask
    answer = RagRuby.ask(params[:question])
    render json: {
      answer: answer.text,
      sources: answer.sources.map(&:to_h)
    }
  end
end
```

## Architecture

### Ingestion Flow

```
Document → Loader → [Document] → Chunker → [Chunk] → Embedder → [Chunk+Embedding] → Store
```

### Query Flow

```
Question → Embedder → Vector → Store.search → [Chunk] → build_context → Generator → Answer
```

Each stage is independent and swappable. The `Pipeline` class orchestrates the flow.

## Dependencies

| Gem | Purpose | Required? |
|-----|---------|-----------|
| `chunker-ruby` | Text chunking | Yes |
| `zvec-ruby` | Persistent vector storage | Optional |
| `onnx-ruby` | Local ONNX embeddings | Optional |
| `ruby_llm` | Multi-provider LLM generation | Optional |

## Development

```bash
git clone https://github.com/johannesdwicahyo/rag-ruby.git
cd rag-ruby
bundle install
bundle exec rake test
```

## License

MIT License. See [LICENSE](LICENSE) for details.
