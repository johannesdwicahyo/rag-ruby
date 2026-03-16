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

      def search(embedding, top_k: 5, filter: nil, strategy: :similarity, lambda: 0.5, fetch_k: 20)
        results = @entries.values

        if filter
          results = results.select do |entry|
            filter.all? { |k, v| entry.metadata[k] == v }
          end
        end

        scored = results
          .map { |entry| [entry, cosine_similarity(embedding, entry.embedding)] }
          .sort_by { |_, score| -score }

        if strategy == :mmr
          mmr_select(scored, embedding, top_k: top_k, lambda: lambda, fetch_k: fetch_k)
        else
          scored.first(top_k)
            .map { |entry, score| { id: entry.id, score: score, metadata: entry.metadata, chunk: entry.chunk } }
        end
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

      # Maximal Marginal Relevance: balances relevance and diversity
      def mmr_select(scored, query_embedding, top_k:, lambda:, fetch_k:)
        candidates = scored.first(fetch_k)
        return [] if candidates.empty?

        selected = []
        remaining = candidates.dup

        top_k.times do
          break if remaining.empty?

          best = nil
          best_mmr = -Float::INFINITY

          remaining.each do |entry, relevance|
            if selected.empty?
              diversity = 0.0
            else
              diversity = selected.map { |sel, _| cosine_similarity(entry.embedding, sel.embedding) }.max
            end

            mmr_score = lambda * relevance - (1.0 - lambda) * diversity

            if mmr_score > best_mmr
              best_mmr = mmr_score
              best = [entry, relevance]
            end
          end

          break unless best
          selected << best
          remaining.delete(best)
        end

        selected.map { |entry, score| { id: entry.id, score: score, metadata: entry.metadata, chunk: entry.chunk } }
      end
    end
  end
end
