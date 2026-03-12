# frozen_string_literal: true

require "open3"

module Tonberry
  module Tools
    module ExecCommand
      ALLOWED_COMMANDS = %w[git ls mv rm].freeze

      class InputSchema < Anthropic::BaseModel
        required :command, String, doc: "The command to run (only 'git', 'ls', 'mv' and 'rm' are allowed)"

        doc "Run the given command in local"
      end

      class Tool < Anthropic::BaseTool
        input_schema InputSchema

        def call(command:)
          executable = command.split.first
          unless ALLOWED_COMMANDS.include?(executable)
            return "Error: '#{executable}' is not allowed. Only the following commands are allowed: #{ALLOWED_COMMANDS.join(", ")}"
          end

          args = command.split[1..]
          if args.any? { |arg| arg.start_with?("/") || arg.include?("..") }
            return "Error: Paths outside the current directory are not allowed."
          end

          output, _ = Open3.capture2e(command, chdir: Dir.pwd)
          output
        end
      end
    end
  end
end
