#coding: utf-8
class LinkRepliesController < ApplicationController
  before_filter :authenticate_user!, :except => [:show]
  layout false
  def show
    Rails.logger.info "=================hello"
    @link_reply = LinkReply.find(params[:id])
  end

  def create
    Rails.logger.info "=================hi"
    @reply = LinkReply.new(params[:link_reply])
    @reply.user = current_user
    @reply.save
  end

  def like
    @re = TweetReply.find(params[:id])
    if @re.like(current_user)
      render :json => {:status => "ok", :count => @re.like_count }
    else
      render :json => {:status => "error", :message => "이미 공감하셨습니다."}
    end
  end
  def blame
    @re = TweetReply.find(params[:id])
    if @re.blame(current_user)
      render :json => {:status => "ok", :count => @re.blame_count }
    else
      render :json => {:status => "error", :message => "이미 공감하셨습니다."}
    end
  end
end
