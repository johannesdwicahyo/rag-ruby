# frozen_string_literal: true

require "test_helper"

class TestPipeline < Minitest::Test
  def setup
    @fixtures = File.expand_path("fixtures", __dir__)
    @embedder = StubEmbedder.new(dimension: 4)
    @generator = StubGenerator.new(response: "The answer is here.")
    @store = RagRuby::Stores::Memory.new(dimension: 4)

    @pipeline = RagRuby::Pipeline.new do |config|
      config.loader :file
      config.chunker :recursive_character, chunk_size: 200, chunk_overlap: 50
      config.embedder_instance = @embedder
      config.store_instance = @store
      config.generator_instance = @generator
    end
  end

  def test_ingest_file
    @pipeline.ingest(File.join(@fixtures, "sample.txt"))
    assert @store.count > 0
  end

  def test_ingest_and_query
    @pipeline.ingest(File.join(@fixtures, "sample.txt"))

    answer = @pipeline.query("What is this document about?")
    assert_instance_of RagRuby::Answer, answer
    assert_equal "The answer is here.", answer.text
    assert answer.sources.size > 0
    assert answer.duration > 0
    assert_equal "What is this document about?", answer.query
    assert_equal 100, answer.tokens_used[:prompt]
    assert_equal 20, answer.tokens_used[:completion]
  end

  def test_ingest_directory
    @pipeline.ingest_directory(@fixtures, glob: "*.{txt,md}")
    assert @store.count > 0
  end

  def test_callbacks
    events = []

    pipeline = RagRuby::Pipeline.new do |config|
      config.loader :file
      config.chunker :recursive_character, chunk_size: 200, chunk_overlap: 50
      config.embedder_instance = @embedder
      config.store_instance = @store
      config.generator_instance = @generator

      config.on(:before_load) { |src| events << [:before_load, src] }
      config.on(:after_load) { |docs| events << [:after_load, docs.size] }
      config.on(:before_chunk) { |doc| events << [:before_chunk] }
      config.on(:after_chunk) { |chunks| events << [:after_chunk, chunks.size] }
    end

    pipeline.ingest(File.join(@fixtures, "sample.txt"))

    event_names = events.map(&:first)
    assert_includes event_names, :before_load
    assert_includes event_names, :after_load
    assert_includes event_names, :before_chunk
    assert_includes event_names, :after_chunk
  end

  def test_query_with_options
    @pipeline.ingest(File.join(@fixtures, "sample.txt"))

    answer = @pipeline.query(
      "test query",
      top_k: 2,
      temperature: 0.0,
      system_prompt: "Be brief."
    )

    assert_equal "The answer is here.", answer.text
    assert_equal "Be brief.", @generator.last_system_prompt
  end

  def test_empty_document_skipped
    # Create pipeline and ingest empty content — should not crash
    pipeline = RagRuby::Pipeline.new do |config|
      config.embedder_instance = @embedder
      config.store_instance = @store
      config.generator_instance = @generator
    end

    # Manually create an empty doc loader
    empty_loader = Class.new(RagRuby::Loaders::Base) do
      def load(_source)
        [RagRuby::Document.new(content: "")]
      end
    end

    pipeline.ingest("anything", loader: empty_loader.new)
    assert_equal 0, @store.count
  end
end

class TestConfiguration < Minitest::Test
  def test_default_chunker_config
    config = RagRuby::Configuration.new
    assert_equal 1000, config.chunk_size
    assert_equal 200, config.chunk_overlap
    assert_equal :recursive_character, config.chunk_strategy
  end

  def test_chunker_config
    config = RagRuby::Configuration.new
    config.chunker :markdown, chunk_size: 500, chunk_overlap: 100
    assert_equal 500, config.chunk_size
    assert_equal 100, config.chunk_overlap
    assert_equal :markdown, config.chunk_strategy
  end

  def test_unknown_loader_raises
    config = RagRuby::Configuration.new
    assert_raises(ArgumentError) { config.loader(:nonexistent) }
  end

  def test_unknown_embedder_raises
    config = RagRuby::Configuration.new
    assert_raises(ArgumentError) { config.embedder(:nonexistent) }
  end

  def test_unknown_store_raises
    config = RagRuby::Configuration.new
    assert_raises(ArgumentError) { config.store(:nonexistent) }
  end

  def test_unknown_generator_raises
    config = RagRuby::Configuration.new
    assert_raises(ArgumentError) { config.generator(:nonexistent) }
  end
end

class TestRagRubyModule < Minitest::Test
  def teardown
    RagRuby.reset!
  end

  def test_configure
    RagRuby.configure do |config|
      config.embedder_instance = StubEmbedder.new
      config.store_instance = RagRuby::Stores::Memory.new
      config.generator_instance = StubGenerator.new
    end

    assert_instance_of RagRuby::Pipeline, RagRuby.pipeline
  end

  def test_configure_from_hash
    hash = {
      "chunker" => { "strategy" => "recursive_character", "chunk_size" => 500 },
      "store" => { "provider" => "memory", "dimension" => 4 }
    }

    RagRuby.configure_from_hash(hash)
    assert_equal 500, RagRuby.pipeline.config.chunk_size
    assert_instance_of RagRuby::Stores::Memory, RagRuby.pipeline.config.store_instance
  end
end
