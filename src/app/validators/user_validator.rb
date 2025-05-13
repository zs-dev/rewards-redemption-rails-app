class UserValidator
  # Validates whether the ID is a valid integer and exists in the database.
  #
  # @param id [String, Integer]
  #
  # @return [Hash]
  def self.validate(id)
    unless id.to_s.match?(/\A-?\d+\z/)
      return { valid: false, error: 'User id must be an integer.', status: :unprocessable_entity }
    end
    id = id.to_i
    unless User.exists?(id)
      return { valid: false, error: 'The user does not exist.', status: :not_found }
    end

    { valid: true }
  end
end
