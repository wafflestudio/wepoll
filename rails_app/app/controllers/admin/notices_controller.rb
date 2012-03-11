class Admin::NoticesController < Admin::AdminController
  def index
    @notices = Notice.page(params[:page]).desc('created_at').per(20)
  end

  def new
    @notice = Notice.new
  end

  def show
    @notice = Notice.find(params[:id])
  end

  def edit
    @notice = Notice.find(params[:id])
  end

  def update
    @notice = Notice.find(params[:id])

    if @notice.update_attributes(params[:notice])
      redirect_to admin_notice_path(@notice)
    else
      render edit_admin_notice_path
    end
  end

  def create
    @notice = Notice.new(params[:notice])
    if @notice.save
      redirect_to admin_notice_path(@notice)
    else
      render new_admin_notice_path
    end
  end

  def destroy
    @notice = Notice.find(params[:id])
    @notice.destroy

    redirect_to admin_notices_path
  end

end
