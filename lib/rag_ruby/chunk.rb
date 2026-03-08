# frozen_string_literal: true

module RagRuby
  class Chunk
    attr_accessor :text, :embedding, :metadata, :document_source, :index

    def initialize(text:, metadata: {}, document_source: nil, index: 0)
      @text = text
      @metadata = metadata
      @document_source = document_source
      @index = index
      @embedding = nil
    end

    def embedded?
      !@embedding.nil?
    end

    def to_s
      text
    end

    def bytesize
      text.bytesize
    end
  end
end
