# frozen_string_literal: true

require_relative "client"
require_relative "skill_loader"
require_relative "session_manager"

module Tonberry
  class Agent
    def initialize(options = {})
      @client = Tonberry::Client.new(cost_limit_in_dollars: 0.1, model: ENV["TONBERRY_MODEL"]&.to_sym)
      @skill_loader = SkillLoader.new(extra_dirs: options[:skills_dirs])
      @session_manager = SessionManager.new
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
      when /\A\/(\S+)(.*)\z/
        handle_skill($1, $2.strip)
      else
        chat_with_spinner(line)
      end
    end

    def handle_skill(name, args)
      case name
      when "skills"
        list_skills
      when "save"
        save_session(args)
      when "load"
        load_session(args)
      when "sessions"
        list_sessions
      else
        prompt = @skill_loader.load(name, args)
        chat_with_spinner(prompt)
      end
    rescue UnknownSkillError, UnknownSessionError => e
      $stdout.puts Rainbow(e.message).bright.red
    end

    def list_skills
      skills = @skill_loader.list
      if skills.empty?
        $stdout.puts Rainbow("No skills available.").bright.yellow
        return
      end

      $stdout.puts Rainbow("Available skills:").bright.green
      skills.each do |skill|
        line = Rainbow("  /#{skill[:name]}").bright.green
        line += Rainbow(" - #{skill[:description]}").green unless skill[:description].empty?
        $stdout.puts line
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

    def save_session(name)
      saved_name = @session_manager.save(@client.messages, name: name.empty? ? nil : name)
      $stdout.puts Rainbow("Session saved: #{saved_name}").bright.green
    end

    def load_session(name)
      if name.empty?
        $stdout.puts Rainbow("Usage: /load <session_name>").bright.yellow
        return
      end
      messages = @session_manager.load(name)
      @client.load_messages(messages)
      $stdout.puts Rainbow("Session loaded: #{name} (#{messages.size / 2} exchanges)").bright.green
    end

    def list_sessions
      sessions = @session_manager.list
      if sessions.empty?
        $stdout.puts Rainbow("No sessions saved.").bright.yellow
        return
      end

      $stdout.puts Rainbow("Saved sessions:").bright.green
      sessions.each do |session|
        $stdout.puts Rainbow("  #{session[:name]}").bright.green + Rainbow(" - #{session[:saved_at]}").green
      end
    end

    def exit_gracefully
      $stdout.puts Rainbow("bye!").bright.green
      exit 0
    end
  end
end
