# frozen_string_literal: true

module RagRuby
  module Embedders
    class Base
      def embed(text)
        raise NotImplementedError, "#{self.class}#embed must be implemented"
      end

      def embed_batch(texts)
        texts.map { |t| embed(t) }
      end

      def dimension
        raise NotImplementedError, "#{self.class}#dimension must be implemented"
      end
    end
  end
end
