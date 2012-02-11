class TweetRepliesController < ApplicationController
  def create
    @re = TweetReply.new(params[:tweet_reply])
    @tweet = Tweet.find(params[:tweet_id])
    if @tweet.nil?
      false
    else
      @tweet.tweet_replies << @re
    end
  end

  def recommend
    @re = TweetReply.find(params[:id])
    ip = request.remote_ip
    if @re.recommend(ip)
      render :json => {:status => "ok", :count => @re.recommend_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
  def opposite
    @re = TweetReply.find(params[:id])
    ip = request.remote_ip
    if @re.opposite(ip)
      render :json => {:status => "ok", :count => @re.opposite_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
  def report
    @re = TweetReply.find(params[:id])
    ip = request.remote_ip
    if @re.report(ip)
      render :json => {:status => "ok", :count => @re.report_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end


  
end
