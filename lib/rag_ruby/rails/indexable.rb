# frozen_string_literal: true

module RagRuby
  module Indexable
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def rag_index(column, metadata: nil, chunk_strategy: :recursive_character, on: [:create, :update])
        class_attribute :rag_column, default: column
        class_attribute :rag_metadata_proc, default: metadata
        class_attribute :rag_chunk_strategy, default: chunk_strategy

        if on.include?(:create)
          after_create :rag_index_record
        end

        if on.include?(:update)
          after_update :rag_index_record, if: -> { saved_change_to_attribute?(column) }
        end

        if on.include?(:destroy) || on.include?(:delete)
          after_destroy :rag_remove_record
        end
      end
    end

    private

    def rag_index_record
      content = public_send(self.class.rag_column).to_s
      return if content.strip.empty?

      metadata = {}
      if self.class.rag_metadata_proc
        metadata = self.class.rag_metadata_proc.call(self)
      end

      doc = Document.new(
        content: content,
        metadata: metadata.merge(model: self.class.name, record_id: id),
        source: "#{self.class.name}##{id}"
      )

      RagRuby.pipeline.ingest(doc.source, loader: InlineLoader.new(doc))
    end

    def rag_remove_record
      # Remove from store by metadata filter
      # Implementation depends on store capabilities
    end

    class InlineLoader < Loaders::Base
      def initialize(document)
        @document = document
      end

      def load(_source)
        [@document]
      end
    end
  end
end
