# frozen_string_literal: true

module Tonberry
  module Tools
    module ReadFile
      class InputSchema < Anthropic::BaseModel
        required :file_path, String, doc: "The path of the file to read"
        required :content, String, doc: "The content to read from the file"

        doc "Read the content of the given file"
      end

      class Tool < Anthropic::BaseTool
        input_schema InputSchema

        def call(file_path:, content:)
          resolved = File.expand_path(file_path)
          unless resolved.start_with?(Dir.pwd + "/") || resolved == Dir.pwd
            return "Error: access denied - path is outside the current working directory"
          end

          File.read(resolved)
        end
      end
    end
  end
end
