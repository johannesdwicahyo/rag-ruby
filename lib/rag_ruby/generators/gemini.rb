# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RagRuby
  module Generators
    class Gemini < Base
      ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models"

      def initialize(model: "gemini-2.0-flash", api_key: nil)
        @model = model
        @api_key = api_key || ENV["GEMINI_API_KEY"]
        raise ArgumentError, "Gemini API key is required (set GEMINI_API_KEY or pass api_key:)" unless @api_key
      end

      def generate(prompt:, system_prompt: nil, temperature: 0.7)
        body = {
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { temperature: temperature }
        }
        if system_prompt
          body[:systemInstruction] = { parts: [{ text: system_prompt }] }
        end

        request_with_retry do
          uri = URI.parse("#{ENDPOINT}/#{@model}:generateContent?key=#{@api_key}")
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.open_timeout = 30
          http.read_timeout = 120

          req = Net::HTTP::Post.new(uri)
          req["Content-Type"] = "application/json"
          req.body = JSON.generate(body)

          response = http.request(req)

          unless response.is_a?(Net::HTTPSuccess)
            raise RagRuby::Error, "Gemini API error (#{response.code}): #{response.body}"
          end

          data = JSON.parse(response.body)
          text = data.dig("candidates", 0, "content", "parts", 0, "text")
          raise RagRuby::Error, "Empty response from Gemini" if text.nil?
          usage = data["usageMetadata"] || {}

          {
            text: text,
            tokens_used: {
              prompt: usage["promptTokenCount"],
              completion: usage["candidatesTokenCount"]
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
        e.message.match?(/429|500|502|503/)
      end
    end
  end
end
