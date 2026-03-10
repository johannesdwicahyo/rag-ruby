# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RagRuby
  module Embedders
    class OpenAI < Base
      ENDPOINT = "https://api.openai.com/v1/embeddings"

      DIMENSIONS = {
        "text-embedding-3-small" => 1536,
        "text-embedding-3-large" => 3072,
        "text-embedding-ada-002" => 1536
      }.freeze

      def initialize(model: "text-embedding-3-small", api_key: nil)
        @model = model
        @api_key = api_key || ENV["OPENAI_API_KEY"]
        raise ArgumentError, "OpenAI API key is required (set OPENAI_API_KEY or pass api_key:)" unless @api_key
      end

      def embed(text)
        response = request([text])
        response.dig("data", 0, "embedding")
      end

      def embed_batch(texts)
        response = request(texts)
        response["data"]
          .sort_by { |d| d["index"] }
          .map { |d| d["embedding"] }
      end

      def dimension
        DIMENSIONS.fetch(@model) { 1536 }
      end

      private

      def request(input)
        request_with_retry do
          uri = URI.parse(ENDPOINT)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 30
          http.read_timeout = 60

          req = Net::HTTP::Post.new(uri)
          req["Authorization"] = "Bearer #{@api_key}"
          req["Content-Type"] = "application/json"
          req.body = JSON.generate(model: @model, input: input)

          response = http.request(req)

          unless response.is_a?(Net::HTTPSuccess)
            raise "OpenAI API error (#{response.code}): #{response.body}"
          end

          JSON.parse(response.body)
        end
      end

      def request_with_retry(max_retries: 3)
        retries = 0
        begin
          yield
        rescue => e
          retries += 1
          if retries <= max_retries && retryable?(e)
            sleep(2 ** (retries - 1))
            retry
          end
          raise
        end
      end

      def retryable?(e)
        e.message.match?(/429|500|502|503/)
      end
    end
  end
end
