# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RagRuby
  module Generators
    class Anthropic < Base
      ENDPOINT = "https://api.anthropic.com/v1/messages"

      def initialize(model: "claude-sonnet-4-20250514", api_key: nil, max_tokens: 4096)
        @model = model
        @api_key = api_key || ENV["ANTHROPIC_API_KEY"]
        @max_tokens = max_tokens
        raise ArgumentError, "Anthropic API key is required (set ANTHROPIC_API_KEY or pass api_key:)" unless @api_key
      end

      def generate(prompt:, system_prompt: nil, temperature: 0.7)
        body = {
          model: @model,
          max_tokens: @max_tokens,
          messages: [{ role: "user", content: prompt }],
          temperature: temperature
        }
        body[:system] = system_prompt if system_prompt

        request_with_retry do
          uri = URI.parse(ENDPOINT)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 30
          http.read_timeout = 120

          req = Net::HTTP::Post.new(uri)
          req["x-api-key"] = @api_key
          req["anthropic-version"] = "2023-06-01"
          req["Content-Type"] = "application/json"
          req.body = JSON.generate(body)

          response = http.request(req)

          unless response.is_a?(Net::HTTPSuccess)
            raise RagRuby::Error, "Anthropic API error (#{response.code}): #{response.body}"
          end

          data = JSON.parse(response.body)
          text = data.dig("content", 0, "text")
          raise RagRuby::Error, "Empty response from Anthropic" if text.nil?
          usage = data["usage"] || {}

          {
            text: text,
            tokens_used: {
              prompt: usage["input_tokens"],
              completion: usage["output_tokens"]
            }
          }
        end
      end

      private

      def request_with_retry(max_retries: 3)
        retries = 0
        begin
          yield
        rescue => e
          retries += 1
          if retries <= max_retries && retryable?(e)
            sleep(2**(retries - 1))
            retry
          end
          raise
        end
      end

      def retryable?(e)
        e.message.match?(/429|500|502|503|529/)
      end
    end
  end
end
