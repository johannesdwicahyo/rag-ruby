# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module RagRuby
  module Generators
    class Ollama < Base
      def initialize(model: "llama3.2", base_url: nil)
        @model = model
        @base_url = base_url || ENV["OLLAMA_URL"] || "http://localhost:11434"
      end

      def generate(prompt:, system_prompt: nil, temperature: 0.7)
        uri = URI.parse("#{@base_url}/api/chat")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 30
        http.read_timeout = 300

        messages = []
        messages << { role: "system", content: system_prompt } if system_prompt
        messages << { role: "user", content: prompt }

        body = {
          model: @model,
          messages: messages,
          stream: false,
          options: { temperature: temperature }
        }

        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req.body = JSON.generate(body)

        response = http.request(req)

        unless response.is_a?(Net::HTTPSuccess)
          raise RagRuby::Error, "Ollama API error (#{response.code}): #{response.body}"
        end

        data = JSON.parse(response.body)
        text = data.dig("message", "content")
        raise RagRuby::Error, "Empty response from Ollama" if text.nil?

        {
          text: text,
          tokens_used: {
            prompt: data["prompt_eval_count"],
            completion: data["eval_count"]
          }
        }
      end
    end
  end
end
