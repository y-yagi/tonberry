# frozen_string_literal: true

require "json"
require "time"

module Tonberry
  class SessionManager
    DEFAULT_SESSION_DIR = File.expand_path("~/.config/tonberry/sessions").freeze

    def initialize(session_dir: DEFAULT_SESSION_DIR)
      @session_dir = session_dir
    end

    def save(messages, name: nil)
      FileUtils.mkdir_p(@session_dir)
      name ||= Time.now.strftime("%Y%m%d_%H%M%S")
      name = name.gsub(/[^\w\-]/, "_")
      path = session_path(name)

      data = {
        "saved_at" => Time.now.iso8601,
        "messages" => serialize_messages(messages)
      }
      File.write(path, JSON.pretty_generate(data))
      name
    end

    def load(name)
      path = session_path(name)
      raise UnknownSessionError, name unless File.exist?(path)

      data = JSON.parse(File.read(path))
      File.delete(path)
      deserialize_messages(data["messages"])
    end

    def list
      return [] unless Dir.exist?(@session_dir)

      Dir.glob("#{@session_dir}/*.json").map do |file|
        name = File.basename(file, ".json")
        saved_at = begin
          data = JSON.parse(File.read(file))
          Time.iso8601(data["saved_at"]).strftime("%Y-%m-%d %H:%M:%S")
        rescue
          "unknown"
        end
        {name: name, saved_at: saved_at}
      end.sort_by { |s| s[:name] }
    end

    private

    def session_path(name)
      File.join(@session_dir, "#{name}.json")
    end

    def serialize_messages(messages)
      messages.map do |msg|
        {
          "role" => msg[:role].to_s,
          "content" => msg[:content]
        }
      end
    end

    def deserialize_messages(messages)
      messages.map do |msg|
        content = msg["content"]
        if content.is_a?(Array)
          content = content.map { |c| c.transform_keys(&:to_sym) }
        end
        {role: msg["role"].to_sym, content: content}
      end
    end
  end
end
