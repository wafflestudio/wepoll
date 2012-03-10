class Me::DashboardController < Me::MeController
  layout 'dashboard'
  def index
    @uploaded_links = current_user.timeline_entries.page(params[:page]).per(5)
    @recommend_links = current_user.recommend_timeline_entries.page(params[:page_2]).per(5)
  end
end
