# frozen_string_literal: true

module RagRuby
  module Stores
    class Base
      def add(id, embedding:, metadata: {})
        raise NotImplementedError, "#{self.class}#add must be implemented"
      end

      def search(embedding, top_k:, filter: nil)
        raise NotImplementedError, "#{self.class}#search must be implemented"
      end

      def delete(id)
        raise NotImplementedError, "#{self.class}#delete must be implemented"
      end

      def count
        raise NotImplementedError, "#{self.class}#count must be implemented"
      end
    end
  end
end
