# frozen_string_literal: true

require "test_helper"

class TestAnswer < Minitest::Test
  def test_initialize
    answer = RagRuby::Answer.new(text: "The answer is 42.")
    assert_equal "The answer is 42.", answer.text
    assert_equal [], answer.sources
    assert_equal({}, answer.tokens_used)
    assert_nil answer.duration
    assert_nil answer.query
  end

  def test_to_s
    answer = RagRuby::Answer.new(text: "Hello")
    assert_equal "Hello", answer.to_s
  end

  def test_to_h
    answer = RagRuby::Answer.new(
      text: "Answer",
      tokens_used: { prompt: 100, completion: 20 },
      query: "Question?"
    )
    hash = answer.to_h
    assert_equal "Answer", hash[:text]
    assert_equal "Question?", hash[:query]
  end
end
