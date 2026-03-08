# frozen_string_literal: true

require "rails/generators"

module Rag
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root ::File.expand_path("templates", __dir__)

      desc "Install RagRuby configuration"

      def create_config_file
        template "rag.yml", "config/rag.yml"
      end

      def create_initializer
        template "initializer.rb", "config/initializers/rag_ruby.rb"
      end

      def show_post_install
        say ""
        say "RagRuby installed successfully!", :green
        say ""
        say "Next steps:"
        say "  1. Edit config/rag.yml with your settings"
        say "  2. Set OPENAI_API_KEY in your environment"
        say "  3. Add `include RagRuby::Indexable` to your models"
        say ""
      end
    end
  end
end
