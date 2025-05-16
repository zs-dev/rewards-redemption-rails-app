module Seeds
  class UserSeeder
    def self.seed!
      User.find_or_create_by!(email: 'test@example.com') do |user|
        user.name = 'Test User'
        user.points = 1000
      end
    end
  end
end