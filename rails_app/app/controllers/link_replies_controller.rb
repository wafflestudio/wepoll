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
    @reply = LinkReply.find(params[:id])
    @result = @reply.like(current_user)
  end
  def blame
    @reply = LinkReply.find(params[:id])
    @result = @reply.blame(current_user)
  end
end
