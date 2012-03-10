class Users::SessionsController < Devise::SessionsController
  layout :false, :only => [:new]
  def new
  end
  def after_sign_in_path_for(resource)
    Rails.logger.info "==== after_sign_in_path ===="
    if session["link_sns"]
      session.delete "link_sns"
      me_dashboard_path
    else
      super
    end
  end
end
