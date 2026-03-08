# frozen_string_literal: true

require "test_helper"

class TestFileLoader < Minitest::Test
  def setup
    @loader = RagRuby::Loaders::File.new
    @fixtures = File.expand_path("fixtures", __dir__)
  end

  def test_load_txt_file
    docs = @loader.load(File.join(@fixtures, "sample.txt"))
    assert_equal 1, docs.size
    assert_includes docs.first.content, "sample text file"
    assert_equal ".txt", docs.first.metadata[:extension]
    assert_equal "sample.txt", docs.first.metadata[:filename]
  end

  def test_load_md_file
    docs = @loader.load(File.join(@fixtures, "sample.md"))
    assert_equal 1, docs.size
    assert_includes docs.first.content, "Sample Markdown"
    assert_equal ".md", docs.first.metadata[:extension]
  end

  def test_load_nonexistent_file
    assert_raises(ArgumentError) do
      @loader.load("/nonexistent/file.txt")
    end
  end

  def test_load_unsupported_extension
    assert_raises(ArgumentError) do
      @loader.load("/some/file.xyz")
    end
  end
end

class TestDirectoryLoader < Minitest::Test
  def setup
    @loader = RagRuby::Loaders::Directory.new
    @fixtures = File.expand_path("fixtures", __dir__)
  end

  def test_load_directory
    docs = @loader.load(@fixtures)
    assert docs.size >= 2
    extensions = docs.map { |d| d.metadata[:extension] }
    assert_includes extensions, ".txt"
    assert_includes extensions, ".md"
  end

  def test_load_nonexistent_directory
    assert_raises(ArgumentError) do
      @loader.load("/nonexistent/directory")
    end
  end

  def test_load_with_glob
    loader = RagRuby::Loaders::Directory.new(glob: "*.txt")
    docs = loader.load(@fixtures)
    assert_equal 1, docs.size
    assert_equal ".txt", docs.first.metadata[:extension]
  end
end
