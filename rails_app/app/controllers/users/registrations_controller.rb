#coding : utf-8
require 'open-uri'
require 'oauth2/access_token'
class Users::RegistrationsController < Devise::RegistrationsController
  layout false, :only => [:new, :create, :after_auth]
  def new
    super
  end

  def create
    sns_data = session["user_facebook_data"] || session["user_twitter_data"]
    if sns_data
      uid = sns_data.uid
      tmp_pwd = Devise.friendly_token[0,20]
      params[:user] = {
        password: tmp_pwd,
        userid: (if sns_data['provider']=='facebook'
                 "fb_#{uid}"
                else
                  "tw_#{uid}"
                end),
        password_confirmation: tmp_pwd,
        nickname:
        (if sns_data['provider']=='facebook'
          sns_data['info']['name'] || sns_data['extra']['raw_info']['name']
        else
          sns_data['info']['nickname'] || sns_data['info']['name']
        end)
      }
      pic_url = sns_data["info"]["image"]
      #TODO : 그림 처리가 느리니 이것을 큐로 빼는것 고민해보셈
      params[:user][:profile_picture] = open(pic_url) unless pic_url.nil?
    end
    params[:user][:agree_provision] = true if params[:agree_provision]

    if params[:agree_send_requests]
      params[:user][:fb_req_friend_ids] = params[:friend_ids]
    end

    super
  end

  protected

  def link_sns
    @fb_token = current_user.user_tokens.where(:provider => 'facebook').first
    @tw_token = current_user.user_tokens.where(:provider => 'twitter').first

    Rails.logger.info "===== link_sns ====="
    if session["user_facebook_data"] && @fb_token.nil?
      Rails.logger.info "===== Build token with FB ====="
      session["user_facebook_data"].keys.each do |k|
        Rails.logger.info "===#{k}==="
        Rails.logger.info session["user_facebook_data"][k].to_s
      end
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
      session["user_twitter_data"].keys.each do |k|
        Rails.logger.info "===#{k}==="
        Rails.logger.info session["user_twitter_data"][k].to_s
      end

      uid = session["user_twitter_data"].uid
      secret = session["user_twitter_data"].credentials.secret
      token = session["user_twitter_data"].credentials.token

      @tw_token = current_user.user_tokens.create!(
        :provider => 'twitter', :uid => uid,
        :access_token => token, :access_token_secret => secret,
        :approved => true)
    end
    session.keys.grep(/^user\_facebook/).each {|k| puts "delete #{k}";session.delete k}
    session.keys.grep(/^user\_twitter/).each {|k| puts "delete #{k}";session.delete k}
  end

  def after_sign_up_path_for(resource)
    Rails.logger.info "====after_sign_up_path_for===="
    link_sns
    after_auth_path
#    super
  end

  def after_update_path_for(resource)
    link_sns
    super
  end

  def after_auth
    Rails.logger.info "====after_auth_path===="
    redirect_to root_path
  end
end
