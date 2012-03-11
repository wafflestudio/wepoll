class Users::SessionsController < Devise::SessionsController
  def new
    resource = build_resource
    clean_up_passwords(resource)
    respond_to do |format|
      format.js {render :js => '$.colorbox({href:"/users/sign_in", width: 520, height: 250});'}
      format.html {
        session[:need_login] = true
        render '/devise/sessions/new2.html.erb'
      }
    end
#    respond_with(resource, serialize_options(resource))
#    render :js => '$.colorbox({href:"/users/sign_in", width: 520, height: 250});'
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
