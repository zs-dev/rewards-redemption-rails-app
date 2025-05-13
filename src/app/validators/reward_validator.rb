class RewardValidator
  # Validates whether the ID is a valid integer and exists in the database.
  #
  # @param id [String, Integer]
  #
  # @return [Hash]
  def self.validate(id)
    unless id.to_s.match?(/\A-?\d+\z/)
      return { valid: false, error: 'Reward id must be an integer.', status: :unprocessable_entity }
    end

    unless Reward.exists?(id)
      return { valid: false, error: 'The reward does not exist.', status: :not_found }
    end

    { valid: true }
  end
end
