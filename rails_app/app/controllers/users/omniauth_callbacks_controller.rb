#coding : utf-8
class Users::OmniauthCallbacksController < ApplicationController
  def facebook
    @user = User.find_for_facebook_oauth(request.env["omniauth.auth"], current_user)

    if @user && @user.persisted?
      sign_in_and_redirect @user,
        session["link_sns"] ? {:bypass => true} : {:event => :authentication}
    else
      if current_user && session["link_sns"]
        Rails.logger.info "======= link Facebook ======="
        fb_data = request.env["omniauth.auth"]
        uid = fb_data.extra.raw_info.uid
        secret = fb_data.credentials.secret
        token = fb_data.credentials.token

        fb_token = current_user.user_tokens.create!(
          :provider => 'facebook', :uid => uid,
          :access_token => token, :access_token_secret => secret,
          :approve_key => SecureRandom.hex, :approve_expire_at => 2.hour.from_now.to_i
        )

        AuthMailer.link_sns_verification(fb_token).deliver
        flash[:notice] = "페이스북 연동 확인메일이 전송되었습니다."

        session.delete "link_sns"
        redirect_to me_dashboard_path
      else
        session["user_facebook_data"] = request.env["omniauth.auth"]
        redirect_to new_user_registration_url
      end
    end
  end

  def twitter
    @user = User.find_for_twitter_oauth(request.env["omniauth.auth"], current_user)

    if @user && @user.persisted?
      sign_in_and_redirect @user,
        session["link_sns"] ? {:bypass => true} : {:event => :authentication}
    else
      if current_user && session["link_sns"]
        tw_data = request.env["omniauth.auth"]
        uid = tw_data.uid
        secret = tw_data.credentials.secret
        token = tw_data.credentials.token

        tw_token = current_user.user_tokens.create!(
          :provider => 'twitter', :uid => uid,
          :access_token => token, :access_token_secret => secret,
          :approve_key => SecureRandom.hex, :approve_expire_at => 2.hour.from_now.to_i
        )
        flash[:notice] = "트위터 연동 확인메일이 전송되었습니다."
        AuthMailer.link_sns_verification(tw_token).deliver
        redirect_to me_dashboard_path
      else
        #see http://stackoverflow.com/questions/7117200/devise-for-twitter-cookie-overflow-error
        session["user_twitter_data"] = request.env["omniauth.auth"].except('extra')
        redirect_to new_user_registration_url
      end
    end
  end
end
