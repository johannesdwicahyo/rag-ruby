#!/usr/bin/env ruby
# frozen_string_literal: true

require "rag_ruby"

# Custom pipeline with callbacks and options
pipeline = RagRuby::Pipeline.new do |config|
  config.loader :file
  config.chunker :recursive_character, chunk_size: 500, chunk_overlap: 100
  config.embedder :openai, model: "text-embedding-3-small"
  config.store :memory, dimension: 1536
  config.generator :openai, model: "gpt-4o"

  # Observability callbacks
  config.on(:before_load) { |src| puts "Loading: #{src}" }
  config.on(:after_chunk) { |chunks| puts "Created #{chunks.size} chunks" }
  config.on(:after_embed) { |chunks| puts "Embedded #{chunks.size} chunks" }
  config.on(:after_query) { |q, answer| puts "Query took #{answer.duration}s" }
end

# Ingest multiple files
pipeline.ingest_directory("documents/", glob: "**/*.{md,txt}")

# Query with options
answer = pipeline.query(
  "What changed in v2.0?",
  top_k: 10,
  temperature: 0.0,
  system_prompt: "You are a technical documentation assistant. Be precise and concise."
)

puts answer.text
answer.sources.each do |source|
  puts "  - #{source.document_source} (score: #{source.score.round(3)})"
end
