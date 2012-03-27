class PledgesController < ApplicationController
  before_filter :authenticate_user!
  def like
    @pledge = Pledge.find(params[:id])
    if (cnt=@pledge.liked_by current_user) > 0
      render :json => {:count => cnt}
    else
      render :json => {:err => "already done"}
    end
  end

  def dislike
    @pledge = Pledge.find(params[:id])
    if (cnt=@pledge.disliked_by current_user) > 0
      render :json => {:count => cnt}
    else
      render :json => {:err => "already done"}
    end
  end
end
