#coding: utf-8
class LinkRepliesController < ApplicationController
  before_filter :authenticate_user!, :except => [:show, :list]
  layout false
  def list
    @entry = TimelineEntry.find(params[:link_reply_id])
    @replies = @entry.link_replies[0...@entry.link_replies.count - 3]
  end
  def show
    @link_reply = LinkReply.find(params[:id])
  end

  def create
    @reply = LinkReply.new(params[:link_reply])
    @reply.user = current_user
    @reply.save
    @tabsection = true if !params[:tabsection].nil?
  end

  def like
    @reply = LinkReply.find(params[:id])
    @result = @reply.like(current_user)
  end
  def blame
    @reply = LinkReply.find(params[:id])
    @result = @reply.blame(current_user)
  end
  def destroy
    @reply = LinkReply.find(params[:id])
    @success = false
    @id = params[:id]
    if @reply.user == current_user
      if @reply.destroy
        @success = true
      else
        @success = false
      end
    else
      @success = false
    end
  end
end
