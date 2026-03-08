# frozen_string_literal: true

module RagRuby
  module Generators
    class Base
      def generate(prompt:, system_prompt: nil, temperature: 0.7)
        raise NotImplementedError, "#{self.class}#generate must be implemented"
      end
    end
  end
end
