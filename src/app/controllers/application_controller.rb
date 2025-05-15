class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from StandardError, with: :handle_api_error

  private

  # Unified error handler for API requests.
  #
  # @api private
  # @param exception [StandardError] The rescued exception.
  #
  # @return [void]
  def handle_api_error(exception)
    case exception
    when ActiveRecord::RecordNotFound
      not_found(exception)
    when ActionController::ParameterMissing
      bad_request(exception)
    when ArgumentError, InsufficientPointsError
      unprocessable_entity(exception)
    else
      internal_server_error(exception)
    end
  end

  # Renders a 404 Not Found response.
  #
  # @api private
  # @param exception [ActiveRecord::RecordNotFound]
  #
  # @return [void]
  def not_found(exception)
    render_error(
      status: :not_found,
      message: exception.message
    )
  end

  # Renders a 400 Bad Request response.
  #
  # @api private
  # @param exception [ActionController::ParameterMissing]
  #
  # @return [void]
  def bad_request(exception)
    render_error(
      status: :bad_request,
      message: exception.message
    )
  end

  # Renders a 422 Unprocessable Entity response.
  #
  # @api private
  # @param exception [ArgumentError]
  #
  # @return [void]
  def unprocessable_entity(exception)
    render_error(
      status: :unprocessable_entity,
      message: exception.message
    )
  end

  # Renders a 422 Unprocessable Entity response for point-related errors.
  #
  # @api private
  # @param exception [InsufficientPointsError]
  #
  # @return [void]
  def insufficient_points(exception)
    render_error(
      status: :unprocessable_entity,
      message: exception.message
    )
  end

  # Renders a 500 Internal Server Error response.
  #
  # @api private
  # @param exception [StandardError]
  #
  # @return [void]
  def internal_server_error(exception)
    render_error(
      status: :internal_server_error,
      message: exception.message
    )
  end

  # Base method for rendering JSON error responses.
  #
  # @api private
  # @param status [Symbol] HTTP status code (e.g., :not_found).
  # @param message [String] User-facing error message.
  # @param details [Hash, nil] Additional debug info (shown only in development/test).
  #
  # @return [void]
  def render_error(status:, message:, details: nil)
    response = { error: message }
    render json: response, status: status
  end
end