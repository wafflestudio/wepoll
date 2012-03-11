class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :prepare_links

  def authenticate_user!
    if current_user.nil?
      render :js => '$.colorbox({href:"/users/sign_in", width: 520, height: 250});'
    else
      true
    end
  end
  def prepare_links
    @recent_timeline_entries = TimelineEntry.all.desc("created_at").limit(20)
    #TODO : 인기 링크 정렬 방식 고민
    @popular_timeline_entries = TimelineEntry.all.desc("recommend_count").limit(20)
  end
  def back
    request.env["HTTP_REFERER"] || "/"
  end
end
