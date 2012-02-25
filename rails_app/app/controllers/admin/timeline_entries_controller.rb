class Admin::TimelineEntriesController < Admin::AdminController
  def index
    @timeline_entries = TimelineEntry.page(params[:page]).per(20)
  end
end
