# frozen_string_literal: true

module Tonberry
  module Tools
    module ListFiles
      EXCLUDED_DIRS = %w[.git].freeze

      class InputSchema < Anthropic::BaseModel
        optional :path, String, doc: "The directory path to list files from (defaults to current directory)"

        doc "List files in the given directory, excluding directories specified in EXCLUDED_DIRS (e.g. .git)"
      end

      class Tool < Anthropic::BaseTool
        input_schema InputSchema

        def call(path: nil)
          target = path ? File.expand_path(path) : Dir.pwd

          unless target.start_with?(Dir.pwd)
            return "Error: access denied - path is outside the current working directory"
          end

          files = Dir.glob("**/*", base: target).reject do |f|
            parts = f.split(File::SEPARATOR)
            parts.any? { |part| EXCLUDED_DIRS.include?(part) }
          end

          files.sort.join("\n")
        end
      end
    end
  end
end
