#!/usr/bin/env ruby
# frozen_string_literal: true

# This example shows how RagRuby integrates with Rails.
# In a real Rails app, this is handled automatically via the Railtie.

# 1. Install: rails g rag:install
#    This creates config/rag.yml and config/initializers/rag_ruby.rb

# 2. Add to your model:
#
#   class Article < ApplicationRecord
#     include RagRuby::Indexable
#
#     rag_index :content,
#       metadata: ->(article) { { category: article.category } },
#       on: [:create, :update]
#   end

# 3. Use in your controller:
#
#   class ChatController < ApplicationController
#     def ask
#       answer = RagRuby.ask(params[:question],
#         scope: Article.where(published: true)
#       )
#       render json: {
#         answer: answer.text,
#         sources: answer.sources.map(&:to_h)
#       }
#     end
#   end

# 4. Or use the global API:
#
#   results = RagRuby.search("How to get started?", top_k: 5)
#   answer = RagRuby.ask("How to get started?")
