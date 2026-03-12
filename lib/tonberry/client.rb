# frozen_string_literal: true

require "anthropic"
require "base64"
require_relative "tools/exec_command"
require_relative "tools/write_file"
require_relative "tools/read_file"
require_relative "cost"

module Tonberry
  class CostLimitExceededError < StandardError
    def initialize(estimated_dollars, limit_dollars)
      super("Estimated input cost $#{estimated_dollars} exceeds limit $#{limit_dollars}")
    end
  end

  class Client
    MAX_TOKENS = 1024
    MAX_INPUT_TOKENS = 20_000

    def initialize(cost_limit_in_dollars: nil)
      @anthropic = Anthropic::Client.new
      @model = :"claude-sonnet-4-6"
      @messages = []
      @cost_limit_in_microcents = cost_limit_in_dollars ? Money.wrap(cost_limit_in_dollars.to_d).in_microcents : nil
    end

    def chat(content)
      record_message(role: :user, content:)
      tools = [
        {name: "exec_command", input_schema: Tools::ExecCommand::InputSchema},
        {name: "write_file", input_schema: Tools::WriteFile::InputSchema},
        {name: "read_file", input_schema: Tools::ReadFile::InputSchema},
      ]

      check_cost_limit!(tools) if @cost_limit_in_microcents

      response = @anthropic.messages.create(
        max_tokens: MAX_TOKENS, model: @model, messages: @messages, tools: tools
      )

      cost = Cost.from_llm_response(response)
      current_response = response

      loop do
        tool_use_blocks = current_response.content.select { |c| c.is_a?(Anthropic::Models::ToolUseBlock) }
        text_blocks = current_response.content.select { |c| c.is_a?(Anthropic::TextBlock) }

        assistant_content = []
        text_blocks.each do |content|
          assistant_content << {type: "text", text: content.text}
          yield content.text if block_given?
        end
        tool_use_blocks.each do |content|
          assistant_content << {type: "tool_use", id: content.id, name: content.name, input: content.input}
        end
        record_message(role: :assistant, content: assistant_content)

        break if tool_use_blocks.empty?

        tool_results = tool_use_blocks.map do |content|
          tool_result = case content.name
                        when "read_file"
                          Tools::ReadFile::Tool.new.call(file_path: content.input[:file_path], content: "")
                        when "write_file"
                          Tools::WriteFile::Tool.new.call(file_path: content.input[:file_path], content: content.input[:content])
                          "Write a file to #{content.input[:file_path]}"
                        when "exec_command"
                          Tools::ExecCommand::Tool.new.call(command: content.input[:command])
                        else
                          "Unknown tool: #{content.name}"
                        end
          yield tool_result if block_given?
          {type: "tool_result", tool_use_id: content.id, content: tool_result.to_s}
        end
        record_message(role: :user, content: tool_results)

        current_response = @anthropic.messages.create(
          max_tokens: MAX_TOKENS, model: @model, messages: @messages, tools: tools
        )
        cost = cost + Cost.from_llm_response(current_response)
      end

      total_dollars = Money.wrap(cost.in_microcents).in_dollars
      input_dollars = Money.wrap(cost.input_cost_in_microcents).in_dollars
      output_dollars = Money.wrap(cost.output_cost_in_microcents).in_dollars
      "[Cost: $#{total_dollars} (input: #{cost.input_tokens} tokens / $#{input_dollars}, output: #{cost.output_tokens} tokens / $#{output_dollars})]"
    end

    private

    def check_cost_limit!(tools)
      token_count = @anthropic.messages.count_tokens(
        model: @model, messages: @messages, tools: tools
      )
      estimated_cost = Cost.new(model_id: @model, input_tokens: token_count.input_tokens, output_tokens: 0)
      if estimated_cost.input_cost_in_microcents > @cost_limit_in_microcents
        limit_dollars = Money.wrap(@cost_limit_in_microcents).in_dollars
        estimated_dollars = Money.wrap(estimated_cost.input_cost_in_microcents).in_dollars
        raise CostLimitExceededError.new(estimated_dollars, limit_dollars)
      end
    end

    def record_message(role:, content:)
      @messages << {role:, content:}
#      trim_history_if_needed
    end

    def trim_history_if_needed
      return if @messages.size < 4

      loop do
        response = @anthropic.messages.count_tokens(model: @model, messages: @messages, tools: [])
        break if response.input_tokens <= MAX_INPUT_TOKENS
        break if @messages.size < 4

        @messages.shift(2)

        # Keep removing pairs until the first user message isn't an orphaned tool_result
        while @messages.size >= 2 &&
              @messages.first[:role] == :user &&
              @messages.first[:content].is_a?(Array) &&
              @messages.first[:content].any? { |c| c[:type] == "tool_result" }
          @messages.shift(2)
        end
      end
    end
  end
end
