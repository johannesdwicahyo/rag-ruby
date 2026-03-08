# frozen_string_literal: true

module RagRuby
  module Loaders
    class Directory < Base
      DEFAULT_GLOB = "**/*.{txt,md,markdown}"

      def initialize(glob: DEFAULT_GLOB)
        @glob = glob
        @file_loader = File.new
      end

      def load(dir_path)
        dir_path = ::File.expand_path(dir_path)
        raise ArgumentError, "Directory not found: #{dir_path}" unless ::Dir.exist?(dir_path)

        pattern = ::File.join(dir_path, @glob)
        files = ::Dir.glob(pattern).sort

        files.flat_map do |file_path|
          @file_loader.load(file_path)
        rescue ArgumentError
          # Skip unsupported file types
          []
        end
      end
    end
  end
end
