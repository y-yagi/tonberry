# frozen_string_literal: true

require "rainbow"
require "reline"
require_relative "tonberry/version"
require_relative "tonberry/agent"

module Tonberry
  def self.run(args)
    Agent.new(args).run
  end
end
