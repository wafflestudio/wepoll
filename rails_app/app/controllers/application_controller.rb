#coding : utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :prepare_links

  def authenticate_user!
    if current_user.nil?
      respond_to do |format|
        format.html do
          flash[:error] = "로그인이 필요합니다."
          redirect_to root_path
        end
        format.js do
          render :js => '$.colorbox({href:"/users/sign_in", width: 520, height: 250});'
        end
      end
    else
      true
    end
  end

  def prepare_links
    @recent_messages = Message.desc("created_at").limit(5)
    #TODO : 인기 링크 정렬 방식 고민
    @popular_messages = Message.desc("like_count").limit(5)
    @notices = Notice.desc('created_at').limit(5)
  end
  def back
    request.env["HTTP_REFERER"] || "/"
  end
end
