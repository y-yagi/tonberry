# frozen_string_literal: true

module Tonberry
  class CostLimitExceededError < StandardError
    def initialize(estimated_dollars, limit_dollars)
      super("Estimated input cost $#{estimated_dollars} exceeds limit $#{limit_dollars}")
    end
  end

  class UnknownSkillError < StandardError
    def initialize(name)
      super("Unknown skill: #{name}")
    end
  end
end
