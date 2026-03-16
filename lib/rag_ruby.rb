# frozen_string_literal: true

require_relative "rag_ruby/version"
require_relative "rag_ruby/document"
require_relative "rag_ruby/chunk"
require_relative "rag_ruby/source"
require_relative "rag_ruby/answer"
require_relative "rag_ruby/prompt_template"

require_relative "rag_ruby/loaders/base"
require_relative "rag_ruby/loaders/file"
require_relative "rag_ruby/loaders/directory"
require_relative "rag_ruby/loaders/url"
require_relative "rag_ruby/loaders/active_record"

require_relative "rag_ruby/embedders/base"
require_relative "rag_ruby/embedders/openai"
require_relative "rag_ruby/embedders/cohere"
require_relative "rag_ruby/embedders/voyage"
require_relative "rag_ruby/embedders/ollama"
require_relative "rag_ruby/embedders/hugging_face"

require_relative "rag_ruby/stores/base"
require_relative "rag_ruby/stores/memory"

require_relative "rag_ruby/generators/base"
require_relative "rag_ruby/generators/openai"
require_relative "rag_ruby/generators/anthropic"
require_relative "rag_ruby/generators/gemini"
require_relative "rag_ruby/generators/ollama"

require_relative "rag_ruby/configuration"
require_relative "rag_ruby/pipeline"

module RagRuby
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class EmbeddingError < Error; end
  class GenerationError < Error; end

  class << self
    def pipeline
      @pipeline ||= Pipeline.new
    end

    def configure(&block)
      @pipeline = Pipeline.new(&block)
    end

    def configure_from_hash(hash)
      @pipeline = Pipeline.new do |config|
        if (chunker_config = hash["chunker"])
          config.chunker(
            (chunker_config["strategy"] || "recursive_character").to_sym,
            chunk_size: chunker_config["chunk_size"] || 1000,
            chunk_overlap: chunker_config["chunk_overlap"] || 200
          )
        end

        if (embedder_config = hash["embedder"])
          provider = (embedder_config["provider"] || "openai").to_sym
          opts = embedder_config.reject { |k, _| k == "provider" }
            .transform_keys(&:to_sym)
          config.embedder(provider, **opts)
        end

        if (store_config = hash["store"])
          provider = (store_config["provider"] || "memory").to_sym
          opts = store_config.reject { |k, _| k == "provider" }
            .transform_keys(&:to_sym)
          config.store(provider, **opts)
        end

        if (gen_config = hash["generator"])
          provider = (gen_config["provider"] || "openai").to_sym
          opts = gen_config.reject { |k, _| k == "provider" }
            .transform_keys(&:to_sym)
          config.generator(provider, **opts)
        end
      end
    end

    def search(query, top_k: 5, filter: nil)
      embedding = pipeline.config.embedder_instance.embed(query)
      pipeline.config.store_instance.search(embedding, top_k: top_k, filter: filter)
    end

    def ask(question, **opts)
      pipeline.query(question, **opts)
    end

    def reset!
      @pipeline = nil
    end
  end
end

# Auto-load Rails integration when Rails is present
if defined?(Rails)
  require_relative "rag_ruby/rails/railtie"
  require_relative "rag_ruby/rails/indexable"
end
