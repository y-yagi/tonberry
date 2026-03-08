# frozen_string_literal: true

require "rainbow"
require "reline"
require_relative "tonberry/version"
require_relative "tonberry/client"

module Tonberry
  def self.run(args)
    client = Tonberry::Client.new(cost_limit_in_dollars: 0.1)

    begin
      while line = Reline.readline(Rainbow("> ").bright, true)
        case line.chomp
        when "exit", "quit", "q"
          $stdout.puts Rainbow("bye!").bright.green
          exit 0
        when ""
          # Do nothing
        else
          begin
            $stdout.puts Rainbow(client.chat(line)).bright.green
          rescue CostLimitExceededError => e
            $stdout.puts Rainbow(e.message).bright.red
          end
        end
      end
    rescue Interrupt, EOFError
      $stdout.puts Rainbow("bye!").bright.green
      exit 0
    end
  end
end
