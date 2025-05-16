class UsersController < ApplicationController
  # Retrieves and renders the user's balance.
  #
  # @return [JSON] The user's balance with HTTP 200 status.
  #
  # @raise [ActiveRecord::RecordNotFound] When the user doesn't exist (404).
  # @raise [ArgumentError] When invalid parameters are provided (422).
  def balance
    render json: { balance: UserService.get_balance(params[:id]) }, status: :ok
  end
end
