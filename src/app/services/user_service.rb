class UserService
  # Get user's points balance.
  #
  # @param id [Integer]
  #
  # @return [Integer]
  #
  # @raise [ActiveRecord::RecordNotFound]
  # @raise [ArgumentError]
  def self.get_balance(id)
    id = id.to_s.strip
    validation_result = UserValidator.validate(id)
    unless validation_result[:valid]
      raise validation_result[:status] == :not_found ?
              ActiveRecord::RecordNotFound :
              ArgumentError, validation_result[:error]
    end

    user = User.find(id)
    user.points
  end
end
