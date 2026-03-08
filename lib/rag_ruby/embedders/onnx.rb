# frozen_string_literal: true

module RagRuby
  module Embedders
    class Onnx < Base
      def initialize(model: "all-MiniLM-L6-v2", model_path: nil)
        @model = model
        @model_path = model_path

        begin
          require "onnx_ruby"
        rescue LoadError
          raise LoadError, "onnx-ruby gem is required for ONNX embeddings. Add `gem 'onnx-ruby'` to your Gemfile."
        end

        @session = create_session
      end

      def embed(text)
        @session.embed(text)
      end

      def embed_batch(texts)
        texts.map { |t| embed(t) }
      end

      def dimension
        384 # all-MiniLM-L6-v2 default
      end

      private

      def create_session
        if @model_path
          OnnxRuby::Session.new(@model_path)
        else
          OnnxRuby::Session.from_pretrained(@model)
        end
      end
    end
  end
end
