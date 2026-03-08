# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RagRuby
  module Generators
    class OpenAI < Base
      ENDPOINT = "https://api.openai.com/v1/chat/completions"

      def initialize(model: "gpt-4o", api_key: nil)
        @model = model
        @api_key = api_key || ENV["OPENAI_API_KEY"]
        raise ArgumentError, "OpenAI API key is required (set OPENAI_API_KEY or pass api_key:)" unless @api_key
      end

      def generate(prompt:, system_prompt: nil, temperature: 0.7)
        messages = []
        messages << { role: "system", content: system_prompt } if system_prompt
        messages << { role: "user", content: prompt }

        body = {
          model: @model,
          messages: messages,
          temperature: temperature
        }

        uri = URI.parse(ENDPOINT)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 30
        http.read_timeout = 120

        req = Net::HTTP::Post.new(uri)
        req["Authorization"] = "Bearer #{@api_key}"
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)

        response = http.request(req)

        unless response.is_a?(Net::HTTPSuccess)
          raise "OpenAI API error (#{response.code}): #{response.body}"
        end

        data = JSON.parse(response.body)
        text = data.dig("choices", 0, "message", "content")
        usage = data["usage"] || {}

        {
          text: text,
          tokens_used: {
            prompt: usage["prompt_tokens"],
            completion: usage["completion_tokens"]
          }
        }
      end
    end
  end
end
