class Admin::PledgesController < Admin::AdminController
  def index
    @pledges = Pledge.page(params[:page]).per(20)
  end

  def new
    @pledge = Pledge.new
  end

  def update
    @pledge = Pledge.find(params[:id])
    if @pledge.update_attribute(params[:pledge])
      redirect_to admin_pledge_path(@pledge)
    else
      render edit_admin_pledge_path
    end
  end

  def edit
    @pledge = Pledge.find(params[:id])
    @politician = @pledge.politician
  end

  def create
    @pledge = Pledge.new(params[:pledge])
    if @pledge.save
      redirect_to admin_pledges_path
    else
      render new_admin_pledge_path
    end
  end

  def destroy
    @pledge = Pledge.find(params[:id])
    @pledge.destroy
    redirect_to admin_pledges_path
  end

  def show
    @pledge = Pledge.find(params[:id])
  end

  def search
    @pledges = Pledge.find(:all, :conditions => {:title => /#{params[:query]}/}).page(params[:page]).per(20)
    render :action => 'index'
  end
end
