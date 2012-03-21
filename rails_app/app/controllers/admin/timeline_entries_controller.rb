class Admin::TimelineEntriesController < Admin::AdminController
  def index
    @timeline_entries = TimelineEntry.page(params[:page]).per(20)
  end

  def destroy
    @timeline_entry = TimelineEntry.find(params[:id])
    @timeline_entry.destroy
    redirect_to admin_timeline_entries_path
  end

  def show
    @timeline_entry = TimelineEntry.find(params[:id])
  end
end
