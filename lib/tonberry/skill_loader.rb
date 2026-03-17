# frozen_string_literal: true

module Tonberry
  class SkillLoader
    SKILL_DIRS = [
      File.expand_path("~/.config/tonberry/skills"),
      File.join(__dir__, "../../skills")
    ].freeze

    def load(name, args = "")
      file = find_skill_file(name)
      raise UnknownSkillError, name unless file

      body = strip_frontmatter(File.read(file))
      args.empty? ? body : "#{body}\n\n#{args}"
    end

    def list
      SKILL_DIRS.each_with_object([]) do |dir, skills|
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
      SKILL_DIRS.map { |d| "#{d}/#{name}.md" }.find { |f| File.exist?(f) }
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
