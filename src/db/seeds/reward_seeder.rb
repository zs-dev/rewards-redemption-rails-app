module Seeds
  class RewardSeeder
    def self.seed!
      rewards = [
        { name: 'Bag of chips', points: 100 },
        { name: "Free meal at McDonald's for one", points: 200 },
        { name: '$10 Amazon gift card', points: 300 },
        { name: 'Movie theater tickets for two', points: 400 },
        { name: 'Wireless earbuds', points: 500 }
      ]

      rewards.each do |reward|
        Reward.find_or_create_by!(reward)
      end
    end
  end
end
