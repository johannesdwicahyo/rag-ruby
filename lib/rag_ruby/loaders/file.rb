# frozen_string_literal: true

module RagRuby
  module Loaders
    class File < Base
      SUPPORTED_EXTENSIONS = %w[.txt .md .markdown].freeze

      def load(path)
        path = ::File.expand_path(path)
        raise ArgumentError, "File not found: #{path}" unless ::File.exist?(path)

        ext = ::File.extname(path).downcase
        unless SUPPORTED_EXTENSIONS.include?(ext)
          raise ArgumentError, "Unsupported file type: #{ext}. Supported: #{SUPPORTED_EXTENSIONS.join(', ')}"
        end

        content = ::File.read(path, encoding: "UTF-8")

        [Document.new(
          content: content,
          metadata: {
            source: path,
            filename: ::File.basename(path),
            extension: ext,
            size: ::File.size(path)
          },
          source: path
        )]
      end
    end
  end
end
