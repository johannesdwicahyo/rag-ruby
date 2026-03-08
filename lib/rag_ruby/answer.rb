# frozen_string_literal: true

module RagRuby
  class Answer
    attr_reader :text, :sources, :tokens_used, :duration, :query

    def initialize(text:, sources: [], tokens_used: {}, duration: nil, query: nil)
      @text = text
      @sources = sources
      @tokens_used = tokens_used
      @duration = duration
      @query = query
    end

    def to_s
      text
    end

    def to_h
      {
        text: text,
        sources: sources.map(&:to_h),
        tokens_used: tokens_used,
        duration: duration,
        query: query
      }
    end
  end
end
