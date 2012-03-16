class Admin::LinkRepliesController < Admin::AdminController
  def index
    @link_replies = LinkReply.page(params[:page]).per(20)
  end

  def show
    @link_reply = LinkReply.find(params[:id])
  end

  def destroy
    @link_reply = LinkReply.find(params[:id])
    @link_reply.destroy
    redirect_to admin_link_replies_path
  end
end
