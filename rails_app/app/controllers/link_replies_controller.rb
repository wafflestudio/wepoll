class LinkRepliesController < ApplicationController
  layout false
  def show
    Rails.logger.info "=================hello"
    @link_reply = LinkReply.find(params[:id])
  end
end
