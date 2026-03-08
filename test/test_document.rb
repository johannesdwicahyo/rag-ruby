# frozen_string_literal: true

require "test_helper"

class TestDocument < Minitest::Test
  def test_initialize_with_content
    doc = RagRuby::Document.new(content: "Hello world")
    assert_equal "Hello world", doc.content
    assert_equal({}, doc.metadata)
    assert_nil doc.source
  end

  def test_initialize_with_all_attributes
    doc = RagRuby::Document.new(
      content: "Hello",
      metadata: { author: "test" },
      source: "/path/to/file.txt"
    )
    assert_equal "Hello", doc.content
    assert_equal({ author: "test" }, doc.metadata)
    assert_equal "/path/to/file.txt", doc.source
  end

  def test_to_s
    doc = RagRuby::Document.new(content: "Hello")
    assert_equal "Hello", doc.to_s
  end

  def test_empty
    assert RagRuby::Document.new(content: "").empty?
    assert RagRuby::Document.new(content: "  ").empty?
    refute RagRuby::Document.new(content: "hello").empty?
  end

  def test_bytesize
    doc = RagRuby::Document.new(content: "Hello")
    assert_equal 5, doc.bytesize
  end
end
