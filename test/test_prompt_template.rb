# frozen_string_literal: true

require "test_helper"

class TestPromptTemplate < Minitest::Test
  def test_default_render
    template = RagRuby::PromptTemplate.new
    result = template.render(context: "Some context", question: "What is it?")

    assert_includes result, "Some context"
    assert_includes result, "What is it?"
  end

  def test_custom_template
    template = RagRuby::PromptTemplate.new(
      user_template: "Context: {{context}}\nQ: {{question}}"
    )
    result = template.render(context: "ctx", question: "q")
    assert_equal "Context: ctx\nQ: q", result
  end

  def test_system_prompt
    template = RagRuby::PromptTemplate.new(system_prompt: "You are helpful.")
    assert_equal "You are helpful.", template.system_prompt
  end
end
