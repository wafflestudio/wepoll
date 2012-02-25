#coding:utf-8
class TweetRepliesController < ApplicationController
  def create
    @re = TweetReply.new(:content => params[:content])
    @tweet = Tweet.find(params[:tweet_id])
    if @tweet.nil?
      render :json => {:status => "error", :message => "오류가 발생했습니다."}
    else
      @tweet.tweet_replies << @re
      @re.save
      render :json => {:status => "ok", :reply => @re }
    end
  end

  def recommend
    @re = TweetReply.find(params[:tweet_reply_id])
    ip = request.remote_ip
    if @re.recommend(ip)
      render :json => {:status => "ok", :count => @re.recommend_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
  def opposite
    @re = TweetReply.find(params[:tweet_reply_id])
    ip = request.remote_ip
    if @re.opposite(ip)
      render :json => {:status => "ok", :count => @re.opposite_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end
  def report
    @re = TweetReply.find(params[:tweet_reply_id])
    ip = request.remote_ip
    if @re.report(ip)
      render :json => {:status => "ok", :count => @re.report_count }
    else
      render :json => {:status => "error", :message => "이미 투표하셨습니다."}
    end
  end


  
end
