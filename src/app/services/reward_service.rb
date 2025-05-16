class RewardService
  # Get all available rewards.
  #
  # @return [ActiveRecord::Relation]
  def self.get_available_rewards
    Reward.all
  end

  # Get the reward by its id.
  #
  # @param id [Integer]
  #
  # @return [Reward]
  #
  # @raise [ActiveRecord::RecordNotFound]
  # @raise [ArgumentError]
  def self.get_reward_by_id(id)
    id = id.to_s.strip
    validation_result = RewardValidator.validate(id)

    unless validation_result[:valid]
      raise validation_result[:status] == :not_found ?
              ActiveRecord::RecordNotFound :
              ArgumentError, validation_result[:error]
    end

    Reward.find(id)
  end
end
