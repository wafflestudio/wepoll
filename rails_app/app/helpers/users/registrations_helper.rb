module Users::RegistrationsHelper
  def signed_via_facebook?
    !session["user_facebook_data"].nil?
  end

  def signed_via_twitter?
    !session["user_twitter_data"].nil?
  end
end
