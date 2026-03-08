# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rag_ruby"
require "minitest/autorun"
require "webmock/minitest"

# Stub embedder for testing — returns deterministic embeddings
class StubEmbedder < RagRuby::Embedders::Base
  def initialize(dimension: 4)
    @dimension = dimension
    @call_count = 0
  end

  def embed(text)
    @call_count += 1
    # Deterministic: hash the text to produce a consistent vector
    seed = text.bytes.sum
    rng = Random.new(seed)
    Array.new(@dimension) { rng.rand(-1.0..1.0) }
  end

  def embed_batch(texts)
    texts.map { |t| embed(t) }
  end

  def dimension
    @dimension
  end
end

# Stub generator for testing
class StubGenerator < RagRuby::Generators::Base
  attr_reader :last_prompt, :last_system_prompt

  def initialize(response: "This is a test answer.")
    @response = response
  end

  def generate(prompt:, system_prompt: nil, temperature: 0.7)
    @last_prompt = prompt
    @last_system_prompt = system_prompt
    { text: @response, tokens_used: { prompt: 100, completion: 20 } }
  end
end
