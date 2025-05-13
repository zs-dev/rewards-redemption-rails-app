class RewardsController < ApplicationController
  # Lists all available rewards.
  #
  # @return [JsonResponse] Renders JSON array of rewards.
  def index
    render json: RewardService.get_available_rewards, status: :ok
  end

  # Shows a specific reward by ID.
  #
  # @return [JSON] The redemption details on 201 success.
  #
  # @raise [ActiveRecord::RecordNotFound] When the reward doesn't exist (404).
  # @raise [ArgumentError] When invalid parameters are provided (422).
  def show
    render json: RewardService.get_reward_by_id(params[:id]), status: :ok
  end
end
