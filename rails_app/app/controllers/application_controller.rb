class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :prepare_links

  def prepare_links
    @recent_timeline_entries = TimelineEntry.all.desc("created_at").limit(20)
    #TODO : 인기 링크 정렬 방식 고민
    @popular_timeline_entries = TimelineEntry.all.desc("created_at").limit(20)
  end
end
