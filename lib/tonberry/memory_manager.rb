# frozen_string_literal: true

require "json"
require "time"
require "fileutils"

module Tonberry
  class MemoryManager
    DEFAULT_MEMORY_FILE = File.expand_path("~/.config/tonberry/memories.json").freeze

    def initialize(memory_file: DEFAULT_MEMORY_FILE)
      @memory_file = memory_file
    end

    def remember(content, name: nil)
      memories = load_all
      name ||= Time.now.strftime("%Y%m%d_%H%M%S")
      name = name.gsub(/[^\w\-]/, "_")
      memories << {"name" => name, "content" => content, "created_at" => Time.now.iso8601}
      save_all(memories)
      name
    end

    def forget(name)
      memories = load_all
      original_size = memories.size
      memories.reject! { |m| m["name"] == name }
      raise UnknownMemoryError, name if memories.size == original_size
      save_all(memories)
    end

    def list
      load_all
    end

    def to_system_prompt
      memories = load_all
      return nil if memories.empty?

      parts = ["The following are persistent memories from the user:"]
      memories.each do |m|
        parts << "- [#{m["name"]}] #{m["content"]}"
      end
      parts.join("\n")
    end

    private

    def load_all
      return [] unless File.exist?(@memory_file)
      JSON.parse(File.read(@memory_file))
    rescue
      []
    end

    def save_all(memories)
      FileUtils.mkdir_p(File.dirname(@memory_file))
      File.write(@memory_file, JSON.pretty_generate(memories))
    end
  end
end
