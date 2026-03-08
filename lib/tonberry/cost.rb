# frozen_string_literal: true

require "ruby_llm"
require "bigdecimal"
require "bigdecimal/util"
require_relative "money"

module Tonberry
  class Cost
    attr_reader :model_id, :input_tokens, :output_tokens

    class << self
      def from_llm_response(response)
        new(
          model_id: response.model,
          input_tokens: response.usage.input_tokens,
          output_tokens: response.usage.output_tokens
        )
      end
    end

    def initialize(model_id:, input_tokens:, output_tokens:)
      @model_id = model_id.to_s
      @input_tokens = input_tokens
      @output_tokens = output_tokens
    end

    def in_microcents
      input_cost_in_microcents + output_cost_in_microcents
    end

    def input_cost_in_microcents
      calculate_token_cost(@input_tokens, model_info.input_price_per_million)
    end

    def output_cost_in_microcents
      calculate_token_cost(@output_tokens, model_info.output_price_per_million)
    end

    private

    def calculate_token_cost(token_count, price_per_million)
      return 0 unless price_per_million

      single_token_price = price_per_million.to_d / 1_000_000
      token_cost_dollars = token_count * single_token_price
      Money.wrap(token_cost_dollars).in_microcents
    end

    def model_info
      @model_info ||= RubyLLM.models.find(@model_id)
    end
  end
end
