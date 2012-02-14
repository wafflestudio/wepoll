#coding : utf-8
class Me::SnsController < ApplicationController
  before_filter :authenticate_user!, :except => :verify_sns_link
  def index
  end

  def verify_sns_link
    @user = User.where(:_id => params[:user_id]).first
    @user_token = UserToken.where(:_id => params[:token_id]).first

    if @user.nil? ||
      @user_token.nil? ||
      @user_token.user_id != @user.id ||
      @user_token.approve_key != params[:key] ||
      @user_token.approve_expire_at < Time.now.to_i

      flash[:error] = "SNS 인증에 실패했습니다."
      redirect_to root_path
    else
      @user_token.update_attribute(:approved, true)
      flash[:notice] = "SNS 인증이 성공적으로 완료되었습니다."
      if user_signed_in?
        if current_user.id != @user.id
          sign_out(current_user)
          sign_in_and_redirect @user, :event => :authentication
        else
          redirect_to me_dashboard_path
        end
      else
        sign_in_and_redirect @user, :event => :authentication
      end
    end
  end

  def link
    session["link_sns"] = true
    redirect_to user_omniauth_authorize_path(params[:provider])
  end

  def mail_resend
    @token = current_user.user_tokens.where(:provider => params[:provider]).first
  end

  def send_sns_link_auth_mail
    @token = UserToken.find(params[:token_id])
    unless @token.nil?
      Stalker.enqueue('email.send',
                      :type => 'sns_link_auth',
                      :token_id => @token.id)
      flash[:notice] = "페이스북 연동 확인메일이 전송되었습니다."
      redirect_to me_dashboard_path
    else
      flash[:error] = "토큰을 찾을수 없습니다. 오류"
      redirect_to me_dashboard_path
    end
  end
end
