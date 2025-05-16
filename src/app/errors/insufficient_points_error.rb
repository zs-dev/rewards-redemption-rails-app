class InsufficientPointsError < StandardError
  def initialize(msg = "Not enough points")
    super(msg)
  end
end
