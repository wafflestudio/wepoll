class TweetsController < ApplicationController

  def recommend
    @tweet = Tweet.find(params[:id])
    ip = request.remote_ip
    if @tweet.recommend(ip)
      render :json => {:status => "ok", :count => @tweet.recommend_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
  def opposite
    @tweet = Tweet.find(params[:id])
    ip = request.remote_ip
    if @tweet.opposite(ip)
      render :json => {:status => "ok", :count => @tweet.opposite_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
end
