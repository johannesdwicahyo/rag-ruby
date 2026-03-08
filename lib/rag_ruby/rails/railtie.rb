# frozen_string_literal: true

module RagRuby
  class Railtie < ::Rails::Railtie
    initializer "rag_ruby.configure" do |app|
      config_path = app.root.join("config", "rag.yml")

      if config_path.exist?
        require "yaml"
        require "erb"

        yaml = ERB.new(config_path.read).result
        all_config = YAML.safe_load(yaml, aliases: true) || {}
        env_config = all_config[Rails.env] || all_config["default"] || {}

        RagRuby.configure_from_hash(env_config)
      end
    end
  end
end
