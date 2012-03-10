class LinkRepliesController < ApplicationController
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
end
