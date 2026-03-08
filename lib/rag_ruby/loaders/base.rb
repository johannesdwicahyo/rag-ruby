# frozen_string_literal: true

module RagRuby
  module Loaders
    class Base
      def load(source)
        raise NotImplementedError, "#{self.class}#load must be implemented"
      end
    end
  end
end
