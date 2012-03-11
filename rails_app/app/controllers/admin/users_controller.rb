class Admin::UsersController < Admin::AdminController
  def index
    @users = User.page(params[:page]).per(20)
  end

  def show
    @user = User.find(params[:id])
  end

  def suspend
    @user = User.find(params[:id])
  end

  def suspend_cancel
    @user = User.find(params[:id])
    @user.status = {"status" => User::STATUS_OK}
    @user.save!

    redirect_to admin_user_path(@user)
  end

  def suspend_confirm
    reason = params[:reason]
    reason = params[:etc_reason] if reason == 'etc'

    @user = User.find(params[:id])

    h = {"status" =>User::STATUS_SUSPEND, "reason" => reason, "start" =>  Time.now, "end"=> Time.now + params[:days].to_i.days}
    @user.total_suspends << h
    @user.status = h
    @user.save!
    redirect_to admin_user_path(@user)
  end
end
