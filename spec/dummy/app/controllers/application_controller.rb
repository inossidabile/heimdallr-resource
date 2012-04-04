class ApplicationController < ActionController::Base
  protect_from_forgery

  def security_context
    User.current
  end
end
