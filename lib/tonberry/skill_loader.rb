# frozen_string_literal: true

module Tonberry
  class SkillLoader
    DEFAULT_SKILL_DIRS = [
      File.expand_path("~/.config/tonberry/skills"),
      File.join(__dir__, "../../skills")
    ].freeze

    def initialize(extra_dirs: nil)
      @skill_dirs = DEFAULT_SKILL_DIRS.dup
      Array(extra_dirs).each do |dir|
        expanded = File.expand_path(dir)
        raise ArgumentError, "Skills directory not found: #{expanded}" unless Dir.exist?(expanded)

        @skill_dirs.unshift(expanded)
      end
    end

    def load(name, args = "")
      file = find_skill_file(name)
      raise UnknownSkillError, name unless file

      body = strip_frontmatter(File.read(file))
      args.empty? ? body : "#{body}\n\n#{args}"
    end

    def list
      @skill_dirs.each_with_object([]) do |dir, skills|
        next unless Dir.exist?(dir)

        Dir.glob("#{dir}/*.md").each do |file|
          name = File.basename(file, ".md")
          description = extract_description(File.read(file))
          skills << {name:, description:}
        end
      end
    end

    private

    def find_skill_file(name)
      @skill_dirs.map { |d| "#{d}/#{name}.md" }.find { |f| File.exist?(f) }
    end

    def strip_frontmatter(content)
      content.sub(/\A---\n.*?---\n/m, "").strip
    end

    def extract_description(content)
      return "" unless content.start_with?("---\n")

      frontmatter = content[/\A---\n(.*?)---\n/m, 1]
      return "" unless frontmatter

      frontmatter.match(/^description:\s*(.+)$/)&.captures&.first || ""
    end
  end
end
