#!/usr/bin/env ruby
# frozen_string_literal: true

require "rag_ruby"

# Basic RAG pipeline example
pipeline = RagRuby::Pipeline.new do |config|
  config.loader :file
  config.chunker :recursive_character, chunk_size: 1000, chunk_overlap: 200
  config.embedder :openai, model: "text-embedding-3-small"
  config.store :memory, dimension: 1536
  config.generator :openai, model: "gpt-4o"
end

# Ingest documents
pipeline.ingest("documents/manual.txt")

# Query
answer = pipeline.query("How do I reset my password?")
puts answer.text
puts "Sources: #{answer.sources.size}"
puts "Tokens used: #{answer.tokens_used}"
