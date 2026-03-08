# frozen_string_literal: true

require "open3"

module Tonberry
  module Tools
    module ExecCommand
      class InputSchema < Anthropic::BaseModel
        required :command, String, doc: "The command to run"

        doc "Run the given command in local"
      end

      class Tool < Anthropic::BaseTool
        input_schema InputSchema

        def call(command:)
          output, _ = Open3.capture2e(command)
          output
        end
      end
    end
  end
end
