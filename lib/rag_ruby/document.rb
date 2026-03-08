# frozen_string_literal: true

module RagRuby
  class Document
    attr_accessor :content, :metadata, :source

    def initialize(content:, metadata: {}, source: nil)
      @content = content
      @metadata = metadata
      @source = source
    end

    def to_s
      content
    end

    def bytesize
      content.bytesize
    end

    def empty?
      content.nil? || content.strip.empty?
    end
  end
end
