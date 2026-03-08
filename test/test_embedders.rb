# frozen_string_literal: true

require "test_helper"

class TestStubEmbedder < Minitest::Test
  def test_embed_returns_vector
    embedder = StubEmbedder.new(dimension: 4)
    result = embedder.embed("hello")
    assert_equal 4, result.size
    assert result.all? { |v| v.is_a?(Float) }
  end

  def test_embed_is_deterministic
    embedder = StubEmbedder.new(dimension: 4)
    a = embedder.embed("hello")
    b = embedder.embed("hello")
    assert_equal a, b
  end

  def test_embed_batch
    embedder = StubEmbedder.new(dimension: 4)
    results = embedder.embed_batch(["hello", "world"])
    assert_equal 2, results.size
    refute_equal results[0], results[1]
  end

  def test_dimension
    embedder = StubEmbedder.new(dimension: 8)
    assert_equal 8, embedder.dimension
  end
end

class TestOpenAIEmbedder < Minitest::Test
  def test_requires_api_key
    ENV.delete("OPENAI_API_KEY")
    assert_raises(ArgumentError) do
      RagRuby::Embedders::OpenAI.new
    end
  end

  def test_embed_with_api
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: {
          data: [{ embedding: [0.1, 0.2, 0.3], index: 0 }],
          usage: { prompt_tokens: 5, total_tokens: 5 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::OpenAI.new(api_key: "test-key")
    result = embedder.embed("hello")
    assert_equal [0.1, 0.2, 0.3], result
  end

  def test_embed_batch_with_api
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: {
          data: [
            { embedding: [0.1, 0.2], index: 0 },
            { embedding: [0.3, 0.4], index: 1 }
          ],
          usage: { prompt_tokens: 10, total_tokens: 10 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::OpenAI.new(api_key: "test-key")
    results = embedder.embed_batch(["hello", "world"])
    assert_equal 2, results.size
    assert_equal [0.1, 0.2], results[0]
    assert_equal [0.3, 0.4], results[1]
  end

  def test_dimension
    embedder = RagRuby::Embedders::OpenAI.new(api_key: "test-key")
    assert_equal 1536, embedder.dimension
  end
end
