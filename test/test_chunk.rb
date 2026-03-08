# frozen_string_literal: true

require "test_helper"

class TestChunk < Minitest::Test
  def test_initialize
    chunk = RagRuby::Chunk.new(text: "Hello chunk")
    assert_equal "Hello chunk", chunk.text
    assert_equal({}, chunk.metadata)
    assert_nil chunk.document_source
    assert_equal 0, chunk.index
    refute chunk.embedded?
  end

  def test_embedded
    chunk = RagRuby::Chunk.new(text: "Hello")
    refute chunk.embedded?

    chunk.embedding = [0.1, 0.2, 0.3]
    assert chunk.embedded?
  end

  def test_to_s
    chunk = RagRuby::Chunk.new(text: "Hello")
    assert_equal "Hello", chunk.to_s
  end
end
