# frozen_string_literal: true

require_relative "client"

module Tonberry
  class Agent
    def initialize(args)
      @client = Tonberry::Client.new(cost_limit_in_dollars: 0.1, model: ENV["TONBERRY_MODEL"]&.to_sym)
    end

    def run
      begin
        while line = Reline.readline(Rainbow("> ").bright, true)
          process_line(line.chomp)
        end
      rescue Interrupt, EOFError
        exit_gracefully
      end
    end

    private

    def process_line(line)
      case line
      when "exit", "quit", "q"
        exit_gracefully
      when ""
        # Do nothing
      else
        chat_with_spinner(line)
      end
    end

    def chat_with_spinner(line)
      result = nil
      mutex = Mutex.new
      spinner_thread = start_spinner(mutex) { result }

      begin
        cost_info = @client.chat(line) do |output|
          mutex.synchronize do
            $stdout.print "\r\e[K"
            $stdout.puts Rainbow(output.to_s).bright.green
            $stdout.flush
          end
        end
        result = :done
        spinner_thread.join
        $stdout.puts Rainbow(cost_info).bright.green
      rescue CostLimitExceededError => e
        result = :error
        spinner_thread.join
        $stdout.puts Rainbow(e.message).bright.red
      end
    end

    def start_spinner(mutex, &result_check)
      Thread.new do
        spinner_chars = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏]
        i = 0
        while result_check.call.nil?
          mutex.synchronize do
            $stdout.print Rainbow("\r#{spinner_chars[i % spinner_chars.size]} Processing...").green
            $stdout.flush
          end
          sleep 0.5
          i += 1
        end
        $stdout.print "\r\e[K"
        $stdout.flush
      end
    end

    def exit_gracefully
      $stdout.puts Rainbow("bye!").bright.green
      exit 0
    end
  end
end
