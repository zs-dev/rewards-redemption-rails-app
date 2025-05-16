require 'tty-prompt'

namespace :utils do
  desc "Run an interactive TTY prompt example"
  task :prompt => :environment do
    prompt = TTY::Prompt.new
    answer = prompt.select("Choose an option:", %w[Yes No Maybe])
    puts "\nYou selected: #{answer}"
  end
end