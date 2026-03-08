# frozen_string_literal: true

require "fileutils"

module Tonberry
  module Tools
    module WriteFile
      class InputSchema < Anthropic::BaseModel
        required :file_path, String, doc: "The path of the file to write"
        required :content, String, doc: "The content to write to the file"

        doc "Write the given content to a file"
      end

      class Tool < Anthropic::BaseTool
        input_schema InputSchema

        def call(file_path:, content:)
          resolved = File.expand_path(file_path)
          unless resolved.start_with?(Dir.pwd + "/") || resolved == Dir.pwd
            return "Error: access denied - path is outside the current working directory"
          end

          FileUtils.mkdir_p(File.dirname(resolved))
          File.write(resolved, content)
        end
      end
    end
  end
end
