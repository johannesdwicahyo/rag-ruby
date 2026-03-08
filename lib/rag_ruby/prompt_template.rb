# frozen_string_literal: true

module RagRuby
  class PromptTemplate
    DEFAULT_SYSTEM = "You are a helpful assistant that answers questions based on the provided context."

    DEFAULT_USER = <<~PROMPT
      Answer the question based on the following context. If the context doesn't
      contain enough information to answer, say so.

      Context:
      {{context}}

      Question: {{question}}

      Answer:
    PROMPT

    attr_reader :system_prompt, :user_template

    def initialize(system_prompt: DEFAULT_SYSTEM, user_template: DEFAULT_USER)
      @system_prompt = system_prompt
      @user_template = user_template
    end

    def render(context:, question:)
      user_template
        .gsub("{{context}}", context)
        .gsub("{{question}}", question)
    end
  end
end
