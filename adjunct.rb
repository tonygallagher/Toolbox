
# Adjunct - Your own personal assistant.
########################################

# Validates and processes commands to Adjunct.
class Commands
  attr_accessor :exit_requested

  def initialize
    @exit_requested = false
    @valid_commands = {
      commands: ":commands\nLists the valid commands for Adjunct.\n\n",
      exit:     ":exit\nCloses Adjunct.\n\n",
      task:     ":task <name>\nCauses subsequent :timer commands to write a log entry with the time against this task.\nUse without arguments to clear.\n\n",
      timer:	  ":timer <mins>\nStarts a countdown and plays a beep when completed.\n\n"
    }
  end

  def process_command(command)
    command_only = command.split[0].gsub(':', '').to_sym
    return false unless valid? command_only
    case command_only
      when :commands
        print_commands
      when :exit
        @exit_requested = true
      when :task
        set_task command.gsub ':task', ''
      when :timer
        set_timer command.gsub(/[^\d]/, '').to_i
      else
        puts command_only
        puts "That command is not implemented.\n\n"
    end
    true
  end

  def print_commands
    puts "\nValid Adjunct Commands\n=============================\n\n"
    @valid_commands.each_value {|value| puts value}
    puts "\n"
  end

  def set_task(task)
    if task.empty? 
      @task = nil
      puts "* Cleared current task.\n\n"
    else
      @task = task.strip
      puts "* Current task set to '#{@task}'.\n\n"
    end
  end

  def set_timer(mins)
    Thread.new(mins) do |min|
      sleep min*60
      puts "* Here's your timer notification!\n\n"
      print "\a\a\a" # Plays three beeps.
    end
    puts "* Okay. Just set you a timer for #{mins} minute(s).#{@task ? " Logging to '" << @task << "'." : ''}\n\n"
    # Refactor needed here to allow Commands to write to the log.
  end

  def command?(input)
    input[0] == ':'
  end

  def valid?(command)
    @valid_commands.has_key? command
  end
end

class Adjunct
  def initialize(out_file)
    @responses_good = ['Got it.', "Interesting. I've made a note of that.", 'Noted.', 'Right.', 'I see.', 'As you say.']
    @responses_bad = ['Say what?', "Sorry, didn't catch that.", 'Huh?', 'Try again, pal.', 'Derp.']
    @commands = Commands.new
    @out_file = out_file
    welcome
  end

  def welcome
    puts "\nAdjunct\n=============================\n\n"
    puts "* Go ahead; I'm listening. Just type your thoughts and I'll note them down."
    puts "* You can get a list of commands I can execute using ':commands'."
    puts "* Just type ':exit' when you're done.\n\n"
  end

  # Keeps processing lines of input until the user exits.
  def activate
    while input = gets
      begin
        respond_bad unless process_input input.chomp
        break if @commands.exit_requested 
      rescue => e
        puts "* Sorry. Having some issues here. This is what happened:\n#{e.message}\n\n"
      end
    end
  end

  def process_input(input)
    return false if input.empty?
    return @commands.process_command input if @commands.command? input
    write_thought input 
    respond_good
    true
  end

  # Writes a single thought to the text file.
  def write_thought(thought)
    File.open @out_file, 'a' do |f| 
      f.puts "#{Time.new.strftime("%d-%m-%Y %H:%M:%S")} #{thought}"
    end
  end

  def respond_good
    puts "* #{@responses_good.sample}\n\n"
  end

  def respond_bad
    puts "* #{@responses_bad.sample}\n\n"
  end

  def depart
    puts "\n* Okay, see you next time."
  end
end

def main
  adjunct = Adjunct.new 'F:\Dropbox\Joseph\AdjunctLog.txt'
  adjunct.activate
  adjunct.depart
  sleep 2
end

main

__END__