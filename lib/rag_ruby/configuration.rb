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
      cohere: ->(opts) { Embedders::Cohere.new(**opts) }
    }.freeze

    STORE_REGISTRY = {
      zvec: ->(opts) { Stores::Zvec.new(**opts) },
      memory: ->(opts) { Stores::Memory.new(**opts) }
    }.freeze

    GENERATOR_REGISTRY = {
      openai: ->(opts) { Generators::OpenAI.new(**opts) },
      ruby_llm: ->(opts) { Generators::RubyLLM.new(**opts) }
    }.freeze

    attr_accessor :loader_instance, :embedder_instance, :store_instance, :generator_instance,
                  :chunk_size, :chunk_overlap, :chunk_strategy

    def initialize
      @callbacks = Hash.new { |h, k| h[k] = [] }
      @chunk_size = 1000
      @chunk_overlap = 200
      @chunk_strategy = :recursive_character
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

    def on(event, &block)
      @callbacks[event] << block
    end

    def callbacks_for(event)
      @callbacks[event]
    end
  end
end
