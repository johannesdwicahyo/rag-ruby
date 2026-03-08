# frozen_string_literal: true

require "test_helper"

class TestSource < Minitest::Test
  def test_initialize
    chunk = RagRuby::Chunk.new(
      text: "Hello",
      metadata: { page: 1 },
      document_source: "doc.txt"
    )
    source = RagRuby::Source.new(chunk: chunk, score: 0.95)

    assert_equal "Hello", source.text
    assert_equal 0.95, source.score
    assert_equal "doc.txt", source.document_source
    assert_equal({ page: 1 }, source.metadata)
  end

  def test_to_h
    chunk = RagRuby::Chunk.new(text: "Hello", document_source: "doc.txt")
    source = RagRuby::Source.new(chunk: chunk, score: 0.9)
    hash = source.to_h

    assert_equal "Hello", hash[:text]
    assert_equal 0.9, hash[:score]
    assert_equal "doc.txt", hash[:document_source]
  end
end
