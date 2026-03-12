# frozen_string_literal: true

require "open3"

module Tonberry
  module Tools
    module ExecCommand
      ALLOWED_COMMANDS = %w[git ls].freeze

      class InputSchema < Anthropic::BaseModel
        required :command, String, doc: "The command to run (only 'git' and 'ls' are allowed)"

        doc "Run the given command in local"
      end

      class Tool < Anthropic::BaseTool
        input_schema InputSchema

        def call(command:)
          executable = command.split.first
          unless ALLOWED_COMMANDS.include?(executable)
            return "Error: '#{executable}' is not allowed. Only the following commands are allowed: #{ALLOWED_COMMANDS.join(", ")}"
          end

          output, _ = Open3.capture2e(command)
          output
        end
      end
    end
  end
end
