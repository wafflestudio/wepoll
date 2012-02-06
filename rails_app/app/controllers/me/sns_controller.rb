#coding : utf-8
class Me::SnsController < ApplicationController
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
      @user_token.update_attribute(:approved => true)
      flash[:notice] = "SNS 인증이 성공적으로 완료되었습니다."
      sign_in_and_redirect @user, :event => :authentication
    end
  end
end
