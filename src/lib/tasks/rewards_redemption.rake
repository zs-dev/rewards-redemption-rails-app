require 'faraday'
require 'tty-prompt'
require 'json'
require 'tty-table'

namespace :utils do
  desc "Rewards Redemption CLI"
  task :rewards_redemption => :environment do
    prompt = TTY::Prompt.new
    current_user = set_current_user

    def display_menu(prompt)
      prompt.ask("\n=== Rewards Redemption ===\n" \
                   "1. Check points balance\n" \
                   "2. List available rewards\n" \
                   "3. Redeem a reward\n" \
                   "4. View redemption history\n" \
                   "5. Exit\n\n" \
                   "Enter your choice (1-5):",
                 required: true) do |q|
        q.validate(/^[1-5]$/, "Please enter a number 1-5")
        q.messages[:valid?] = 'Invalid option, please try again'
      end
    end

    loop do
      choice = display_menu(prompt)

      case choice
      when "1"
        check_balance(current_user)
      when "2"
        list_rewards
      when "3"
        redeem_reward(current_user)
      when "4"
        view_history(current_user)
      when "5"
        puts "\nGoodbye!"
        break
      end
    end
  end
end

private

# Initializes a Faraday HTTP client.
#
# @api private
#
# @return [Faraday::Connection]
#
def api_client
  base_url = Rails.application.config_for(:rewards).dig('api_base_url')
  Faraday.new(url: base_url) do |f|
    f.request :json
    f.response :json
    f.adapter Faraday.default_adapter
  end
end

# Makes a request to the specified API endpoint
#
# @api private
#
# @param endpoint [String]
# @param headers [Hash]
#
# @return [Hash, nil]
#
# @raise [Faraday::Error]
# @raise [JSON::ParserError]
def api_get(endpoint, headers = {})
  begin
    response = api_client.get(endpoint) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Accept'] = 'application/json'
    end

  response.body

  rescue Faraday::Error => e
    puts "API Connection Failed for #{endpoint}: #{e.message}"
  rescue JSON::ParserError
    puts "Failed to parse JSON response from #{endpoint}"
  end
end

# Sets and returns the current user from configuration.
#
# @api private
#
# @return [User, nil]
def set_current_user
  email = Rails.application.config_for(:rewards).dig('default_user')
  user = User.find_by(email: email)

  unless user
    puts "User not found: #{email}"
    return
  end

  puts "Logged in as: #{user.name} (#{user.email})"
  user
end

# Displays the user's current points balance.
#
# @api private
#
# @param user [User]
def check_balance(user)
  if (balance_data = api_get("/users/#{user.id}/balance"))
    puts "\nCurrent balance: #{balance_data['balance']} points"
  else
    puts "\nFailed to get balance. Status: #{response.status}. Body: #{response.body}"
  end
end

# Lists available rewards in a table.
#
# @api private
def list_rewards
  rewards = api_get("/rewards")

  unless rewards
    puts "Failed to get rewards"
    return
  end

  if rewards.empty?
    puts "There are no rewards available."
    return
  end

  table = TTY::Table.new(
    header: ['ID', 'Reward Name', 'Points'],
    rows: rewards.map { |r| [r['id'], r['name'], r['points']] }
  )

  puts "\nAvailable Rewards:"
  puts table.render(:ascii)
end

# Displays user's redemption history
#
# @api private
#
# @param user [User]
def view_history(user)
  redemptions = api_get("/users/#{user.id}/redemptions/history")

  unless redemptions
    puts "Failed to get history"
    return
  end

  if redemptions.empty?
    TTY::Prompt.new.error("No redemption history found.")
    return
  end

  table_data = redemptions.map do |redemption|
    [
      redemption['created_at'],
      redemption.dig('reward', 'name'),
      redemption.dig('reward', 'points'),
    ]
  end

  puts "\nRedemption History:"
  table = TTY::Table.new(
    header: ['Date', 'Reward', 'Points'],
    rows: table_data
  )
  puts table.render(:unicode, alignments: [:left, :left, :right], padding: [0, 1, 0, 1])
end

# Handles reward redemption.
#
# @api private
#
# @param user [User]
def redeem_reward(user)
  prompt = TTY::Prompt.new

  reward_id = prompt.ask('Enter the ID of the reward you want to redeem:') do |q|
    q.required(true)
    q.validate(/^\d+$/, "Please enter a valid number")
  end

  reward = api_get("/rewards/#{reward_id}")
  if reward['error']
    puts "No reward found with ID: #{reward_id}. Select option 2 to see reward IDs."
    return
  end


  confirm = prompt.ask("Redeem '#{reward['name']}' for #{reward['points']} points? (y/n)") do |q|
    q.required(true)
    q.validate(/^[yn]$/i, "Please enter y or n")
    q.modify :down
    q.convert -> (input) { input == 'y' }
  end

  unless confirm
    puts 'Redemption cancelled'
    return
  end

  response = api_client.post("/redeem") do |req|
    req.headers['Content-Type'] = 'application/json'
    req.body = { user_id: user.id, reward_id: reward_id.to_i}.to_json
  end

  if response&.success?
    puts "\nReward redeemed successfully!"
    if (balance = api_get("/users/#{user.id}/balance"))
      puts "Remaining balance: #{balance['balance'].to_i} points"
    end
  else
    puts "Redemption failed: #{response.body['error']}"
  end
end