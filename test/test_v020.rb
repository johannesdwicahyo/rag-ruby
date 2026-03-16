# frozen_string_literal: true

require "test_helper"

# --- Embedder Tests ---

class TestCohereEmbedder < Minitest::Test
  def test_requires_api_key
    ENV.delete("COHERE_API_KEY")
    assert_raises(ArgumentError) { RagRuby::Embedders::Cohere.new }
  end

  def test_embed
    stub_request(:post, "https://api.cohere.ai/v1/embed")
      .to_return(
        status: 200,
        body: { embeddings: [[0.1, 0.2, 0.3]] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::Cohere.new(api_key: "test-key")
    result = embedder.embed("hello")
    assert_equal [0.1, 0.2, 0.3], result
  end

  def test_embed_batch
    stub_request(:post, "https://api.cohere.ai/v1/embed")
      .to_return(
        status: 200,
        body: { embeddings: [[0.1, 0.2], [0.3, 0.4]] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::Cohere.new(api_key: "test-key")
    results = embedder.embed_batch(["hello", "world"])
    assert_equal 2, results.size
  end

  def test_dimension
    embedder = RagRuby::Embedders::Cohere.new(api_key: "test-key")
    assert_equal 1024, embedder.dimension
  end
end

class TestVoyageEmbedder < Minitest::Test
  def test_requires_api_key
    ENV.delete("VOYAGE_API_KEY")
    assert_raises(ArgumentError) { RagRuby::Embedders::Voyage.new }
  end

  def test_embed
    stub_request(:post, "https://api.voyageai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: { data: [{ embedding: [0.5, 0.6], index: 0 }] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::Voyage.new(api_key: "test-key")
    result = embedder.embed("hello")
    assert_equal [0.5, 0.6], result
  end

  def test_embed_batch_sorts_by_index
    stub_request(:post, "https://api.voyageai.com/v1/embeddings")
      .to_return(
        status: 200,
        body: {
          data: [
            { embedding: [0.3, 0.4], index: 1 },
            { embedding: [0.1, 0.2], index: 0 }
          ]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::Voyage.new(api_key: "test-key")
    results = embedder.embed_batch(["a", "b"])
    assert_equal [0.1, 0.2], results[0]
    assert_equal [0.3, 0.4], results[1]
  end

  def test_dimension
    embedder = RagRuby::Embedders::Voyage.new(api_key: "test-key")
    assert_equal 1024, embedder.dimension
  end

  def test_api_error
    stub_request(:post, "https://api.voyageai.com/v1/embeddings")
      .to_return(status: 401, body: "Unauthorized")

    embedder = RagRuby::Embedders::Voyage.new(api_key: "bad-key")
    assert_raises(RagRuby::Error) { embedder.embed("hello") }
  end
end

class TestOllamaEmbedder < Minitest::Test
  def test_embed
    stub_request(:post, "http://localhost:11434/api/embeddings")
      .to_return(
        status: 200,
        body: { embedding: [0.1, 0.2, 0.3] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::Ollama.new
    result = embedder.embed("hello")
    assert_equal [0.1, 0.2, 0.3], result
  end

  def test_custom_base_url
    stub_request(:post, "http://myhost:11434/api/embeddings")
      .to_return(
        status: 200,
        body: { embedding: [0.4, 0.5] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::Ollama.new(base_url: "http://myhost:11434")
    result = embedder.embed("test")
    assert_equal [0.4, 0.5], result
  end

  def test_dimension
    embedder = RagRuby::Embedders::Ollama.new
    assert_equal 768, embedder.dimension
  end

  def test_api_error
    stub_request(:post, "http://localhost:11434/api/embeddings")
      .to_return(status: 500, body: "Internal error")

    embedder = RagRuby::Embedders::Ollama.new
    assert_raises(RagRuby::Error) { embedder.embed("hello") }
  end
end

class TestHuggingFaceEmbedder < Minitest::Test
  def test_requires_api_key
    ENV.delete("HUGGINGFACE_API_KEY")
    assert_raises(ArgumentError) { RagRuby::Embedders::HuggingFace.new }
  end

  def test_embed
    stub_request(:post, "https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/all-MiniLM-L6-v2")
      .to_return(
        status: 200,
        body: [[0.1, 0.2, 0.3]].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::HuggingFace.new(api_key: "hf_test")
    result = embedder.embed("hello")
    assert_equal [0.1, 0.2, 0.3], result
  end

  def test_embed_with_token_level_output
    # HuggingFace sometimes returns token-level embeddings that need mean pooling
    token_embeddings = [[[1.0, 2.0], [3.0, 4.0]]]
    stub_request(:post, "https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/all-MiniLM-L6-v2")
      .to_return(
        status: 200,
        body: token_embeddings.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    embedder = RagRuby::Embedders::HuggingFace.new(api_key: "hf_test")
    result = embedder.embed("hello")
    assert_equal [2.0, 3.0], result  # mean of [1,3] and [2,4]
  end

  def test_dimension
    embedder = RagRuby::Embedders::HuggingFace.new(api_key: "hf_test")
    assert_equal 384, embedder.dimension
  end
end

# --- Generator Tests ---

class TestAnthropicGenerator < Minitest::Test
  def test_requires_api_key
    ENV.delete("ANTHROPIC_API_KEY")
    assert_raises(ArgumentError) { RagRuby::Generators::Anthropic.new }
  end

  def test_generate
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: {
          content: [{ type: "text", text: "The answer is 42." }],
          usage: { input_tokens: 50, output_tokens: 10 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    gen = RagRuby::Generators::Anthropic.new(api_key: "test-key")
    result = gen.generate(prompt: "What is the answer?")
    assert_equal "The answer is 42.", result[:text]
    assert_equal 50, result[:tokens_used][:prompt]
    assert_equal 10, result[:tokens_used][:completion]
  end

  def test_generate_with_system_prompt
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with { |req| JSON.parse(req.body)["system"] == "Be concise" }
      .to_return(
        status: 200,
        body: {
          content: [{ type: "text", text: "42" }],
          usage: { input_tokens: 30, output_tokens: 1 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    gen = RagRuby::Generators::Anthropic.new(api_key: "test-key")
    result = gen.generate(prompt: "Answer?", system_prompt: "Be concise")
    assert_equal "42", result[:text]
  end

  def test_api_error
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 401, body: "Unauthorized")

    gen = RagRuby::Generators::Anthropic.new(api_key: "bad-key")
    assert_raises(RagRuby::Error) { gen.generate(prompt: "test") }
  end

  def test_sends_correct_headers
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .with(headers: { "x-api-key" => "my-key", "anthropic-version" => "2023-06-01" })
      .to_return(
        status: 200,
        body: { content: [{ text: "ok" }], usage: {} }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    gen = RagRuby::Generators::Anthropic.new(api_key: "my-key")
    result = gen.generate(prompt: "test")
    assert_equal "ok", result[:text]
  end
end

class TestGeminiGenerator < Minitest::Test
  def test_requires_api_key
    ENV.delete("GEMINI_API_KEY")
    assert_raises(ArgumentError) { RagRuby::Generators::Gemini.new }
  end

  def test_generate
    stub_request(:post, /generativelanguage\.googleapis\.com/)
      .to_return(
        status: 200,
        body: {
          candidates: [{ content: { parts: [{ text: "Hello from Gemini!" }] } }],
          usageMetadata: { promptTokenCount: 40, candidatesTokenCount: 5 }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    gen = RagRuby::Generators::Gemini.new(api_key: "test-key")
    result = gen.generate(prompt: "Say hello")
    assert_equal "Hello from Gemini!", result[:text]
    assert_equal 40, result[:tokens_used][:prompt]
    assert_equal 5, result[:tokens_used][:completion]
  end

  def test_generate_with_system_prompt
    stub_request(:post, /generativelanguage\.googleapis\.com/)
      .with { |req| JSON.parse(req.body).key?("systemInstruction") }
      .to_return(
        status: 200,
        body: {
          candidates: [{ content: { parts: [{ text: "Brief." }] } }],
          usageMetadata: {}
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    gen = RagRuby::Generators::Gemini.new(api_key: "test-key")
    result = gen.generate(prompt: "test", system_prompt: "Be brief")
    assert_equal "Brief.", result[:text]
  end

  def test_api_error
    stub_request(:post, /generativelanguage\.googleapis\.com/)
      .to_return(status: 400, body: "Bad request")

    gen = RagRuby::Generators::Gemini.new(api_key: "bad-key")
    assert_raises(RagRuby::Error) { gen.generate(prompt: "test") }
  end
end

class TestOllamaGenerator < Minitest::Test
  def test_generate
    stub_request(:post, "http://localhost:11434/api/chat")
      .to_return(
        status: 200,
        body: {
          message: { role: "assistant", content: "Hello from Ollama!" },
          prompt_eval_count: 20,
          eval_count: 8
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    gen = RagRuby::Generators::Ollama.new
    result = gen.generate(prompt: "Say hello")
    assert_equal "Hello from Ollama!", result[:text]
    assert_equal 20, result[:tokens_used][:prompt]
    assert_equal 8, result[:tokens_used][:completion]
  end

  def test_generate_with_system_prompt
    stub_request(:post, "http://localhost:11434/api/chat")
      .with { |req| JSON.parse(req.body)["messages"].first["role"] == "system" }
      .to_return(
        status: 200,
        body: {
          message: { role: "assistant", content: "Brief." },
          prompt_eval_count: 10,
          eval_count: 2
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    gen = RagRuby::Generators::Ollama.new
    result = gen.generate(prompt: "test", system_prompt: "Be brief")
    assert_equal "Brief.", result[:text]
  end

  def test_custom_base_url
    stub_request(:post, "http://myhost:11434/api/chat")
      .to_return(
        status: 200,
        body: { message: { content: "ok" }, prompt_eval_count: 5, eval_count: 1 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    gen = RagRuby::Generators::Ollama.new(base_url: "http://myhost:11434")
    result = gen.generate(prompt: "test")
    assert_equal "ok", result[:text]
  end

  def test_api_error
    stub_request(:post, "http://localhost:11434/api/chat")
      .to_return(status: 500, body: "Internal error")

    gen = RagRuby::Generators::Ollama.new
    assert_raises(RagRuby::Error) { gen.generate(prompt: "test") }
  end

  def test_stream_disabled
    stub_request(:post, "http://localhost:11434/api/chat")
      .with { |req| JSON.parse(req.body)["stream"] == false }
      .to_return(
        status: 200,
        body: { message: { content: "ok" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    gen = RagRuby::Generators::Ollama.new
    gen.generate(prompt: "test")
  end
end

# --- Configuration Tests ---

class TestConfigurationV020 < Minitest::Test
  def test_new_embedder_registry_entries
    assert RagRuby::Configuration::EMBEDDER_REGISTRY.key?(:voyage)
    assert RagRuby::Configuration::EMBEDDER_REGISTRY.key?(:ollama)
    assert RagRuby::Configuration::EMBEDDER_REGISTRY.key?(:hugging_face)
  end

  def test_new_generator_registry_entries
    assert RagRuby::Configuration::GENERATOR_REGISTRY.key?(:anthropic)
    assert RagRuby::Configuration::GENERATOR_REGISTRY.key?(:gemini)
    assert RagRuby::Configuration::GENERATOR_REGISTRY.key?(:ollama)
  end

  def test_retrieval_strategy_defaults
    config = RagRuby::Configuration.new
    assert_equal :similarity, config.retrieval_strategy
    assert_equal 0.5, config.mmr_lambda
    assert_equal 20, config.mmr_fetch_k
  end

  def test_retrieval_config
    config = RagRuby::Configuration.new
    config.retrieval :mmr, lambda: 0.7, fetch_k: 50
    assert_equal :mmr, config.retrieval_strategy
    assert_equal 0.7, config.mmr_lambda
    assert_equal 50, config.mmr_fetch_k
  end

  def test_reranker_config
    reranker = Object.new
    config = RagRuby::Configuration.new
    config.reranker(reranker)
    assert_equal reranker, config.reranker_instance
  end

  def test_auto_detect_embedder
    ENV["VOYAGE_API_KEY"] = "test"
    assert_equal :voyage, RagRuby::Configuration.detect_embedder
  ensure
    ENV.delete("VOYAGE_API_KEY")
  end

  def test_auto_detect_generator
    ENV["ANTHROPIC_API_KEY"] = "test"
    assert_equal :anthropic, RagRuby::Configuration.detect_generator
  ensure
    ENV.delete("ANTHROPIC_API_KEY")
  end

  def test_auto_detect_returns_nil_when_no_keys
    %w[VOYAGE_API_KEY COHERE_API_KEY HUGGINGFACE_API_KEY OPENAI_API_KEY].each { |k| ENV.delete(k) }
    assert_nil RagRuby::Configuration.detect_embedder
  end
end

# --- MMR Tests ---

class TestMMRRetrieval < Minitest::Test
  def setup
    @store = RagRuby::Stores::Memory.new(dimension: 3)
    # Add vectors that cluster: v1/v2 are similar, v3 is different
    @store.add("1", embedding: [1.0, 0.0, 0.0], chunk: stub_chunk("doc A"))
    @store.add("2", embedding: [0.95, 0.05, 0.0], chunk: stub_chunk("doc A variant"))
    @store.add("3", embedding: [0.0, 1.0, 0.0], chunk: stub_chunk("doc B"))
    @store.add("4", embedding: [0.0, 0.0, 1.0], chunk: stub_chunk("doc C"))
  end

  def test_similarity_search_returns_most_similar
    results = @store.search([1.0, 0.0, 0.0], top_k: 2, strategy: :similarity)
    assert_equal 2, results.size
    assert_equal "1", results[0][:id]
    assert_equal "2", results[1][:id]
  end

  def test_mmr_promotes_diversity
    # With MMR and low lambda (diversity-heavy), should pick doc 1 first (most relevant),
    # then a diverse doc rather than doc 2 (very similar to doc 1)
    results = @store.search([1.0, 0.0, 0.0], top_k: 3, strategy: :mmr, lambda: 0.3)
    ids = results.map { |r| r[:id] }
    assert_equal "1", ids[0]  # most relevant
    # With lambda=0.3, diversity dominates — second pick should be orthogonal
    assert_includes ["3", "4"], ids[1]
  end

  def test_mmr_with_high_lambda_favors_relevance
    results = @store.search([1.0, 0.0, 0.0], top_k: 2, strategy: :mmr, lambda: 0.99)
    ids = results.map { |r| r[:id] }
    # High lambda = almost pure relevance, should be same as similarity
    assert_equal "1", ids[0]
    assert_equal "2", ids[1]
  end

  def test_mmr_empty_store
    store = RagRuby::Stores::Memory.new(dimension: 3)
    results = store.search([1.0, 0.0, 0.0], top_k: 5, strategy: :mmr)
    assert_equal [], results
  end

  private

  def stub_chunk(text)
    Struct.new(:text).new(text)
  end
end

# --- Reranker Integration Tests ---

class TestRerankerIntegration < Minitest::Test
  def test_pipeline_with_reranker
    embedder = StubEmbedder.new(dimension: 3)
    store = RagRuby::Stores::Memory.new(dimension: 3)
    generator = StubGenerator.new(response: "reranked answer")

    # A mock reranker that reverses the order
    reranker = Object.new
    def reranker.rerank(query, documents, top_k: nil)
      documents.each_with_index.map { |_doc, i| { index: i, score: 1.0 - (i * 0.1) } }.reverse
    end

    # Pre-populate store
    store.add("a", embedding: [1.0, 0.0, 0.0], chunk: RagRuby::Chunk.new(text: "first"), metadata: {})
    store.add("b", embedding: [0.5, 0.5, 0.0], chunk: RagRuby::Chunk.new(text: "second"), metadata: {})

    pipeline = RagRuby::Pipeline.new do |config|
      config.embedder_instance = embedder
      config.store_instance = store
      config.generator_instance = generator
      config.reranker(reranker)
    end

    answer = pipeline.query("test query")
    assert_equal "reranked answer", answer.text
  end
end

# --- Pipeline with MMR ---

class TestPipelineMMR < Minitest::Test
  def test_pipeline_with_mmr_strategy
    embedder = StubEmbedder.new(dimension: 3)
    store = RagRuby::Stores::Memory.new(dimension: 3)
    generator = StubGenerator.new(response: "mmr answer")

    store.add("a", embedding: [1.0, 0.0, 0.0], chunk: RagRuby::Chunk.new(text: "first"), metadata: {})
    store.add("b", embedding: [0.95, 0.05, 0.0], chunk: RagRuby::Chunk.new(text: "similar"), metadata: {})
    store.add("c", embedding: [0.0, 1.0, 0.0], chunk: RagRuby::Chunk.new(text: "different"), metadata: {})

    pipeline = RagRuby::Pipeline.new do |config|
      config.embedder_instance = embedder
      config.store_instance = store
      config.generator_instance = generator
      config.retrieval :mmr, lambda: 0.5, fetch_k: 10
    end

    answer = pipeline.query("test query", top_k: 2)
    assert_equal "mmr answer", answer.text
    assert answer.sources.size > 0
  end
end
