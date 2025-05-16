
class RedemptionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Retrieves the user's redemption history.
  #
  # @param user_id [Integer]
  #
  # @return [JsonResponse] A JSON array containing the redemption history on 200 success.
  #
  # @raise [ActiveRecord::RecordNotFound] When the user doesn't exist (404).
  # @raise [ArgumentError] When invalid parameters are provided (422).
  def history
    render json: RedemptionService.get_redemption_history(params[:user_id]), status: :ok
  end


  # Redeems the user's points for a specific reward.
  #
  # @param user_id [Integer] Comes from the request body.
  # @param reward_id [Integer] Comes from the request body.
  #
  # @return [JSON] The redemption details on 201 success.
  #
  # @raise [ActiveRecord::RecordNotFound] When user or reward doesn't exist (404).
  # @raise [InsufficientPointsError] When user lacks sufficient points (422).
  # @raise [ArgumentError] When invalid parameters are provided (422).
  def redeem
    redemption = RedemptionService.redeem_reward(params[:user_id], params[:reward_id])
    render json: redemption, status: :created
  end
end
