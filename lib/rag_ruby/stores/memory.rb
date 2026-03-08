# frozen_string_literal: true

module RagRuby
  module Stores
    class Memory < Base
      Entry = Struct.new(:id, :embedding, :metadata, :chunk, keyword_init: true)

      def initialize(dimension: nil)
        @dimension = dimension
        @entries = {}
      end

      def add(id, embedding:, metadata: {}, chunk: nil)
        @entries[id] = Entry.new(id: id, embedding: embedding, metadata: metadata, chunk: chunk)
      end

      def search(embedding, top_k: 5, filter: nil)
        results = @entries.values

        if filter
          results = results.select do |entry|
            filter.all? { |k, v| entry.metadata[k] == v }
          end
        end

        results
          .map { |entry| [entry, cosine_similarity(embedding, entry.embedding)] }
          .sort_by { |_, score| -score }
          .first(top_k)
          .map { |entry, score| { id: entry.id, score: score, metadata: entry.metadata, chunk: entry.chunk } }
      end

      def delete(id)
        @entries.delete(id)
      end

      def count
        @entries.size
      end

      def clear
        @entries.clear
      end

      private

      def cosine_similarity(a, b)
        dot = a.zip(b).sum { |x, y| x * y }
        mag_a = Math.sqrt(a.sum { |x| x * x })
        mag_b = Math.sqrt(b.sum { |x| x * x })
        return 0.0 if mag_a == 0 || mag_b == 0

        dot / (mag_a * mag_b)
      end
    end
  end
end
