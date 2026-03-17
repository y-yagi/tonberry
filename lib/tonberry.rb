# frozen_string_literal: true

require "rainbow"
require "reline"
require "optparse"
require_relative "tonberry/version"
require_relative "tonberry/agent"
require_relative "tonberry/errors"

module Tonberry
  def self.run(args)
    options = {}
    OptionParser.new do |opts|
      opts.on("--skills-dir DIR", "Additional directory to load skills from (can be specified multiple times)") do |dir|
        (options[:skills_dirs] ||= []) << dir
      end
    end.parse!(args)

    Agent.new(options).run
  end
end
