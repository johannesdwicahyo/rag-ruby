# frozen_string_literal: true

module RagRuby
  module Loaders
    class ActiveRecord < Base
      def initialize(column: :content, metadata_columns: [])
        @column = column
        @metadata_columns = metadata_columns
      end

      def load(scope)
        records = scope.respond_to?(:find_each) ? scope.to_a : [scope]

        records.map do |record|
          content = record.public_send(@column).to_s
          metadata = build_metadata(record)

          Document.new(
            content: content,
            metadata: metadata,
            source: "#{record.class.name}##{record.id}"
          )
        end
      end

      private

      def build_metadata(record)
        meta = { model: record.class.name, id: record.id }
        @metadata_columns.each do |col|
          meta[col] = record.public_send(col) if record.respond_to?(col)
        end
        meta
      end
    end
  end
end
