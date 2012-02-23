#coding : utf-8
require 'oauth2/access_token'
class Users::RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def link_sns
    #XXX
    redirect_to root_path
  end

  protected

  def link_sns
    @fb_token = current_user.user_tokens.where(:provider => 'facebook').first
    @tw_token = current_user.user_tokens.where(:provider => 'twitter').first

    Rails.logger.info "===== link_sns ====="
    Rails.logger.info session["user_facebook_data"].to_s
    if session["user_facebook_data"] && @fb_token.nil?
      Rails.logger.info "===== Build token with FB ====="
      uid = session["user_facebook_data"].uid
      secret = session["user_facebook_data"].credentials.secret
      token = session["user_facebook_data"].credentials.token

      Rails.logger.info "== uid:#{uid} =="
      Rails.logger.info "== secret:#{secret} =="
      Rails.logger.info "== token:#{token} =="

#      current_user.send_facebook(
#        :access_token => token,
#        :message => '안녕!'
#      )

      @fb_token = current_user.user_tokens.create!(
        :provider => 'facebook', :uid => uid,
        :access_token => token, :access_token_secret => secret,
        :approved => true)
    end

    if session["user_twitter_data"] && @tw_token.nil?
      Rails.logger.info "===== Build token with Twitter ====="
      uid = session["user_twitter_data"].uid
      secret = session["user_twitter_data"].credentials.secret
      token = session["user_twitter_data"].credentials.token

      @tw_token = current_user.user_tokens.create!(
        :provider => 'twitter', :uid => uid,
        :access_token => token, :access_token_secret => secret,
        :approved => true)
    end
    session.keys.grep(/^user\_facebook\./).each {|k| session.delete k}
    session.keys.grep(/^user\_twitter\./).each {|k| session.delete k}
  end

  def after_sign_up_path_for(resource)
    link_sns
    super
  end

  def after_update_path_for(resource)
    link_sns
    super
  end
end
