# frozen_string_literal: true

module RagRuby
  module Generators
    class RubyLLM < Base
      def initialize(model: "gpt-4o", provider: nil)
        begin
          require "ruby_llm"
        rescue LoadError
          raise LoadError, "ruby_llm gem is required. Add `gem 'ruby_llm'` to your Gemfile."
        end

        @model = model
        @provider = provider
      end

      def generate(prompt:, system_prompt: nil, temperature: 0.7)
        chat = ::RubyLLM.chat(model: @model)
        chat.with_temperature(temperature)
        chat.with_instructions(system_prompt) if system_prompt

        response = chat.ask(prompt)

        {
          text: response.content,
          tokens_used: {
            prompt: response.input_tokens,
            completion: response.output_tokens
          }
        }
      end
    end
  end
end
