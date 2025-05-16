class RedemptionService
  # Redeem the reward for the user.
  #
  # @param user_id [Integer]
  # @param reward_id [Integer]
  #
  # @return [Redemption]
  def self.redeem_reward(user_id, reward_id)
    user_validation = UserValidator.validate(user_id)
    reward_validation = RewardValidator.validate(reward_id)

    unless user_validation[:valid] && reward_validation[:valid]
      raise_validation_errors(user_validation, reward_validation)
    end
    ActiveRecord::Base.transaction do
      reward = Reward.find_by(id: reward_id)
      user = User.find_by(id: user_id)

      if user.points < reward.points
        raise InsufficientPointsError, "Not enough points."
      end

      user.decrement!(:points, reward.points)
      user.redemptions.create!(reward_id: reward.id)
    end
  end

  # Get the user's redemption history.
  #
  # @param user_id [Integer]
  #
  # @return [Array<Hash>]
  #
  # @raise [ActiveRecord::RecordNotFound]
  # @raise [ArgumentError]
  def self.get_redemption_history(user_id)
    user_id = user_id.to_s.strip
    validation_result = UserValidator.validate(user_id)

    unless validation_result[:valid]
      if validation_result[:status] == :not_found
        raise ActiveRecord::RecordNotFound, validation_result[:error]
      else
        raise ArgumentError, validation_result[:error]
      end
    end

    Redemption.includes(:reward)
              .where(user_id: user_id)
              .map do |redemption|
      {
        id: redemption.id,
        user_id: redemption.user_id,
        created_at: redemption.created_at,
        updated_at: redemption.updated_at,
        reward: {
          id: redemption.reward_id,  # Moved here
          name: redemption.reward&.name,
          points: redemption.reward&.points
        }
      }
    end
  end

  private

  # Raises validation errors based on user/reward validation results.
  #
  # @param user_val [Hash] User validation result.
  # @param reward_val [Hash] Reward validation result (same structure as user_val).
  #
  # @raise [ActiveRecord::RecordNotFound] If either validation hash has :status :not_found.
  # @raise [ArgumentError] For all other validation failures.
  def self.raise_validation_errors(user_val, reward_val)
    if !user_val[:valid]
      raise user_val[:status] == :not_found ?
              ActiveRecord::RecordNotFound :
              ArgumentError, user_val[:error]
    else
      raise reward_val[:status] == :not_found ?
              ActiveRecord::RecordNotFound :
              ArgumentError, reward_val[:error]
    end
  end
end
