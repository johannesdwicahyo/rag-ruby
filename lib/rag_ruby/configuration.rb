# frozen_string_literal: true

module RagRuby
  class Configuration
    LOADER_REGISTRY = {
      file: -> { Loaders::File.new },
      directory: -> { Loaders::Directory.new },
      url: -> { Loaders::URL.new },
      active_record: -> { Loaders::ActiveRecord.new }
    }.freeze

    EMBEDDER_REGISTRY = {
      openai: ->(opts) { Embedders::OpenAI.new(**opts) },
      onnx: ->(opts) { Embedders::Onnx.new(**opts) },
      cohere: ->(opts) { Embedders::Cohere.new(**opts) },
      voyage: ->(opts) { Embedders::Voyage.new(**opts) },
      ollama: ->(opts) { Embedders::Ollama.new(**opts) },
      hugging_face: ->(opts) { Embedders::HuggingFace.new(**opts) }
    }.freeze

    STORE_REGISTRY = {
      zvec: ->(opts) { Stores::Zvec.new(**opts) },
      memory: ->(opts) { Stores::Memory.new(**opts) }
    }.freeze

    GENERATOR_REGISTRY = {
      openai: ->(opts) { Generators::OpenAI.new(**opts) },
      ruby_llm: ->(opts) { Generators::RubyLLM.new(**opts) },
      anthropic: ->(opts) { Generators::Anthropic.new(**opts) },
      gemini: ->(opts) { Generators::Gemini.new(**opts) },
      ollama: ->(opts) { Generators::Ollama.new(**opts) }
    }.freeze

    # Maps API key env vars / prefixes to provider symbols for auto-detection
    AUTO_DETECT_EMBEDDER = {
      "VOYAGE_API_KEY" => :voyage,
      "COHERE_API_KEY" => :cohere,
      "HUGGINGFACE_API_KEY" => :hugging_face,
      "OPENAI_API_KEY" => :openai
    }.freeze

    AUTO_DETECT_GENERATOR = {
      "ANTHROPIC_API_KEY" => :anthropic,
      "GEMINI_API_KEY" => :gemini,
      "OPENAI_API_KEY" => :openai
    }.freeze

    attr_accessor :loader_instance, :embedder_instance, :store_instance, :generator_instance,
                  :reranker_instance,
                  :chunk_size, :chunk_overlap, :chunk_strategy,
                  :retrieval_strategy, :mmr_lambda, :mmr_fetch_k,
                  :http_timeout, :read_timeout

    def initialize
      @callbacks = Hash.new { |h, k| h[k] = [] }
      @chunk_size = 1000
      @chunk_overlap = 200
      @chunk_strategy = :recursive_character
      @retrieval_strategy = :similarity
      @mmr_lambda = 0.5
      @mmr_fetch_k = 20
      @http_timeout = 30
      @read_timeout = 60
    end

    def loader(name, **opts)
      @loader_instance = if LOADER_REGISTRY.key?(name)
                           LOADER_REGISTRY[name].call
                         else
                           raise ArgumentError, "Unknown loader: #{name}"
                         end
    end

    def chunker(strategy, chunk_size: 1000, chunk_overlap: 200)
      @chunk_strategy = strategy
      @chunk_size = chunk_size
      @chunk_overlap = chunk_overlap
    end

    def embedder(name, **opts)
      @embedder_instance = if EMBEDDER_REGISTRY.key?(name)
                             EMBEDDER_REGISTRY[name].call(opts)
                           elsif name.is_a?(Class) || name.respond_to?(:embed)
                             name
                           else
                             raise ArgumentError, "Unknown embedder: #{name}"
                           end
    end

    def store(name, **opts)
      @store_instance = if STORE_REGISTRY.key?(name)
                          STORE_REGISTRY[name].call(opts)
                        elsif name.is_a?(Class) || name.respond_to?(:search)
                          name
                        else
                          raise ArgumentError, "Unknown store: #{name}"
                        end
    end

    def generator(name, **opts)
      @generator_instance = if GENERATOR_REGISTRY.key?(name)
                              GENERATOR_REGISTRY[name].call(opts)
                            elsif name.is_a?(Class) || name.respond_to?(:generate)
                              name
                            else
                              raise ArgumentError, "Unknown generator: #{name}"
                            end
    end

    def reranker(instance)
      @reranker_instance = instance
    end

    def retrieval(strategy, lambda: nil, fetch_k: nil)
      @retrieval_strategy = strategy
      @mmr_lambda = lambda if lambda
      @mmr_fetch_k = fetch_k if fetch_k
    end

    def on(event, &block)
      @callbacks[event] << block
    end

    def callbacks_for(event)
      @callbacks[event]
    end

    # Auto-detect embedder from available API keys
    def self.detect_embedder
      AUTO_DETECT_EMBEDDER.each do |env_var, provider|
        return provider if ENV[env_var] && !ENV[env_var].empty?
      end
      nil
    end

    # Auto-detect generator from available API keys
    def self.detect_generator
      AUTO_DETECT_GENERATOR.each do |env_var, provider|
        return provider if ENV[env_var] && !ENV[env_var].empty?
      end
      nil
    end
  end
end
