#coding: utf-8
class LinkRepliesController < ApplicationController
  before_filter :authenticate_user!, :except => [:show]
  layout false
  def list
    @entry = TimelineEntry.find(params[:link_reply_id])
    @replies = @entry.link_replies[0..@entry.link_replies.count - 3]
  end
  def show
    Rails.logger.info "=================hello"
    @link_reply = LinkReply.find(params[:id])
  end

  def create
    Rails.logger.info "=================hi"
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
end
