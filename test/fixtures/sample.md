# Sample Markdown Document

## Introduction

This is a sample markdown file used for testing the RAG pipeline.

## Getting Started

To get started, install the gem and configure your pipeline:

```ruby
pipeline = RagRuby::Pipeline.new do |config|
  config.embedder :openai
  config.store :memory, dimension: 1536
end
```

## FAQ

**Q: How do I reset my password?**

Go to Settings > Security > Reset Password.

**Q: Where can I find documentation?**

Visit the official documentation site.
