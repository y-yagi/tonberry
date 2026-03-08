# frozen_string_literal: true

module Tonberry
  class Money < Data.define(:value)
    MICROCENTS_PER_DOLLAR = 100 * 1_000_000

    class << self
      def wrap(value)
        microcents = case value
        when self
          value.value
        when Integer
          value
        else
          convert_dollars_to_microcents(value)
        end

        new(microcents)
      end

      private

      def convert_dollars_to_microcents(dollars)
        (dollars.to_d * MICROCENTS_PER_DOLLAR).round.to_i
      end
    end

    def to_i
      in_microcents
    end

    def in_microcents
      value
    end

    def in_dollars
      format("%.6f", in_microcents.to_d / MICROCENTS_PER_DOLLAR)
    end
  end
end
