class NoticesController < ApplicationController
  layout false
  def index
    @notices = Notice.desc('created_at').page(params[:page]).per(5)
  end
end
