# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RagRuby
  module Embedders
    class Cohere < Base
      ENDPOINT = "https://api.cohere.ai/v1/embed"

      def initialize(model: "embed-english-v3.0", api_key: nil)
        @model = model
        @api_key = api_key || ENV["COHERE_API_KEY"]
        raise ArgumentError, "Cohere API key is required (set COHERE_API_KEY or pass api_key:)" unless @api_key
      end

      def embed(text)
        embed_batch([text]).first
      end

      def embed_batch(texts)
        uri = URI.parse(ENDPOINT)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri)
        req["Authorization"] = "Bearer #{@api_key}"
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(
          model: @model,
          texts: texts,
          input_type: "search_document"
        )

        response = http.request(req)

        unless response.is_a?(Net::HTTPSuccess)
          raise "Cohere API error (#{response.code}): #{response.body}"
        end

        parsed = JSON.parse(response.body)
        embeddings = parsed["embeddings"]
        raise RagRuby::Error, "No embeddings in Cohere response" if embeddings.nil? || embeddings.empty?
        embeddings
      end

      def dimension
        1024
      end
    end
  end
end
