# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RagRuby
  module Embedders
    class Voyage < Base
      ENDPOINT = "https://api.voyageai.com/v1/embeddings"

      def initialize(model: "voyage-3", api_key: nil)
        @model = model
        @api_key = api_key || ENV["VOYAGE_API_KEY"]
        raise ArgumentError, "Voyage API key is required (set VOYAGE_API_KEY or pass api_key:)" unless @api_key
      end

      def embed(text)
        embed_batch([text]).first
      end

      def embed_batch(texts)
        uri = URI.parse(ENDPOINT)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 30
        http.read_timeout = 60

        req = Net::HTTP::Post.new(uri)
        req["Authorization"] = "Bearer #{@api_key}"
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(model: @model, input: texts)

        response = http.request(req)
        unless response.is_a?(Net::HTTPSuccess)
          raise RagRuby::Error, "Voyage API error (#{response.code}): #{response.body}"
        end

        parsed = JSON.parse(response.body)
        parsed["data"].sort_by { |d| d["index"] }.map { |d| d["embedding"] }
      end

      def dimension
        1024
      end
    end
  end
end
