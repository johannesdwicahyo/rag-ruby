# frozen_string_literal: true

module RagRuby
  class Source
    attr_reader :chunk, :score, :document_source

    def initialize(chunk:, score:)
      @chunk = chunk
      @score = score
      @document_source = chunk.document_source
    end

    def text
      chunk.text
    end

    def metadata
      chunk.metadata
    end

    def to_h
      {
        text: text,
        score: score,
        document_source: document_source,
        metadata: metadata
      }
    end
  end
end
