# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RagRuby
  module Embedders
    class HuggingFace < Base
      ENDPOINT = "https://api-inference.huggingface.co/pipeline/feature-extraction"

      def initialize(model: "sentence-transformers/all-MiniLM-L6-v2", api_key: nil)
        @model = model
        @api_key = api_key || ENV["HUGGINGFACE_API_KEY"]
        raise ArgumentError, "HuggingFace API key is required (set HUGGINGFACE_API_KEY or pass api_key:)" unless @api_key
      end

      def embed(text)
        embed_batch([text]).first
      end

      def embed_batch(texts)
        uri = URI.parse("#{ENDPOINT}/#{@model}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 30
        http.read_timeout = 120

        req = Net::HTTP::Post.new(uri)
        req["Authorization"] = "Bearer #{@api_key}"
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(inputs: texts)

        response = http.request(req)
        unless response.is_a?(Net::HTTPSuccess)
          raise RagRuby::Error, "HuggingFace API error (#{response.code}): #{response.body}"
        end

        embeddings = JSON.parse(response.body)
        # HF returns [[token_embeddings]] for each text — mean pool if needed
        embeddings.map { |e| e.first.is_a?(Array) ? mean_pool(e) : e }
      end

      def dimension
        384
      end

      private

      def mean_pool(token_embeddings)
        dim = token_embeddings.first.length
        count = token_embeddings.length.to_f
        sum = Array.new(dim, 0.0)
        token_embeddings.each do |vec|
          vec.each_with_index { |v, i| sum[i] += v }
        end
        sum.map { |v| v / count }
      end
    end
  end
end
