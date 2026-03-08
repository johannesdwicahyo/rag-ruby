# frozen_string_literal: true

require "test_helper"

class TestMemoryStore < Minitest::Test
  def setup
    @store = RagRuby::Stores::Memory.new(dimension: 3)
  end

  def test_add_and_count
    @store.add("1", embedding: [1.0, 0.0, 0.0])
    @store.add("2", embedding: [0.0, 1.0, 0.0])
    assert_equal 2, @store.count
  end

  def test_search
    @store.add("1", embedding: [1.0, 0.0, 0.0], metadata: { type: "a" })
    @store.add("2", embedding: [0.9, 0.1, 0.0], metadata: { type: "a" })
    @store.add("3", embedding: [0.0, 0.0, 1.0], metadata: { type: "b" })

    results = @store.search([1.0, 0.0, 0.0], top_k: 2)
    assert_equal 2, results.size
    assert_equal "1", results.first[:id]
    assert results.first[:score] > results.last[:score]
  end

  def test_search_with_filter
    @store.add("1", embedding: [1.0, 0.0, 0.0], metadata: { type: "a" })
    @store.add("2", embedding: [0.9, 0.1, 0.0], metadata: { type: "b" })

    results = @store.search([1.0, 0.0, 0.0], top_k: 5, filter: { type: "b" })
    assert_equal 1, results.size
    assert_equal "2", results.first[:id]
  end

  def test_delete
    @store.add("1", embedding: [1.0, 0.0, 0.0])
    assert_equal 1, @store.count

    @store.delete("1")
    assert_equal 0, @store.count
  end

  def test_clear
    @store.add("1", embedding: [1.0, 0.0, 0.0])
    @store.add("2", embedding: [0.0, 1.0, 0.0])
    @store.clear
    assert_equal 0, @store.count
  end
end
