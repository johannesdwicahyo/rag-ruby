# frozen_string_literal: true

module RagRuby
  module Stores
    class Zvec < Base
      def initialize(path:, dimension:)
        @path = path
        @dimension = dimension

        begin
          require "zvec"
        rescue LoadError
          raise LoadError, "zvec-ruby gem is required for Zvec store. Add `gem 'zvec-ruby'` to your Gemfile."
        end

        @index = ::Zvec::Index.new(path: path, dimension: dimension)
      end

      def add(id, embedding:, metadata: {}, chunk: nil)
        @index.add(id, embedding: embedding, metadata: metadata)
      end

      def search(embedding, top_k: 5, filter: nil)
        results = @index.search(embedding, top_k: top_k)

        if filter
          results = results.select do |r|
            filter.all? { |k, v| r[:metadata][k] == v }
          end
        end

        results
      end

      def delete(id)
        @index.delete(id)
      end

      def count
        @index.count
      end
    end
  end
end
