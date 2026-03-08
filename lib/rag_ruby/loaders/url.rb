# frozen_string_literal: true

require "net/http"
require "uri"

module RagRuby
  module Loaders
    class URL < Base
      def initialize(timeout: 30)
        @timeout = timeout
      end

      def load(url)
        uri = URI.parse(url)
        raise ArgumentError, "Invalid URL: #{url}" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

        response = fetch(uri)
        content = response.body.force_encoding("UTF-8")

        [Document.new(
          content: content,
          metadata: {
            source: url,
            content_type: response["content-type"],
            status: response.code.to_i
          },
          source: url
        )]
      end

      private

      def fetch(uri, redirect_limit: 5)
        raise "Too many redirects" if redirect_limit == 0

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @timeout
        http.read_timeout = @timeout

        request = Net::HTTP::Get.new(uri)
        response = http.request(request)

        case response
        when Net::HTTPRedirection
          fetch(URI.parse(response["location"]), redirect_limit: redirect_limit - 1)
        when Net::HTTPSuccess
          response
        else
          raise "HTTP #{response.code}: #{response.message}"
        end
      end
    end
  end
end
