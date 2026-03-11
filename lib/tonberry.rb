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
            result = nil
            spinner_thread = Thread.new do
              spinner_chars = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏]
              i = 0
              while result.nil?
                $stdout.print Rainbow("\r#{spinner_chars[i % spinner_chars.size]} Processing...").green
                $stdout.flush
                sleep 0.5
                i += 1
              end
              $stdout.print "\r\e[K"
              $stdout.flush
            end

            result = client.chat(line)
            spinner_thread.join

            $stdout.puts Rainbow(result).bright.green
          rescue CostLimitExceededError => e
            result = :error
            spinner_thread&.join
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
