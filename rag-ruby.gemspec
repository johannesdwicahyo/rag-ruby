# frozen_string_literal: true

require_relative "lib/rag_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "rag-ruby"
  spec.version = RagRuby::VERSION
  spec.authors = ["Johannes Dwi Cahyo"]
  spec.email = ["johannes@example.com"]

  spec.summary = "RAG (Retrieval-Augmented Generation) pipeline framework for Ruby and Rails"
  spec.description = "A batteries-included RAG framework that orchestrates document loading, " \
                     "chunking, embedding, vector storage, retrieval, and generation. " \
                     "Think LangChain for Ruby — simpler, more opinionated, and Rails-native."
  spec.homepage = "https://github.com/johannesdwicahyo/rag-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?("test/", "spec/", "examples/", ".git")
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "chunker-ruby", "~> 0.1"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
