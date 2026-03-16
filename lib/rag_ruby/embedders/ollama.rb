# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RagRuby
  module Embedders
    class Ollama < Base
      def initialize(model: "nomic-embed-text", base_url: nil)
        @model = model
        @base_url = base_url || ENV["OLLAMA_URL"] || "http://localhost:11434"
      end

      def embed(text)
        uri = URI.parse("#{@base_url}/api/embeddings")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 30
        http.read_timeout = 120

        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(model: @model, prompt: text)

        response = http.request(req)
        unless response.is_a?(Net::HTTPSuccess)
          raise RagRuby::Error, "Ollama API error (#{response.code}): #{response.body}"
        end

        JSON.parse(response.body)["embedding"]
      end

      def dimension
        768
      end
    end
  end
end
