class Me::DashboardController < Me::MeController
  layout 'dashboard'
  def index
    @uploaded_messages = current_user.messages.page(params[:page]).per(5)
    @recommend_messages = current_user.like_messages.page(params[:page_2]).per(5)
  end
end
