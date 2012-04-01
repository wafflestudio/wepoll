class MessageRepliesController < ApplicationController
  def index
    @message = Message.find(params[:message_id])
    @replies = @message.message_replies.desc('created_at')
  end

  def create
    @re = MessageReply.new(params[:message_reply])
    @re.user = current_user
    @message = Message.find(params[:message_id])
    @errror = 0
    @message.message_replies << @re
    if @re.save
      @replies = @message.message_replies.desc('created_at')
    else
      @error = 1
    end
  end

  def destroy
    @message_reply = MessageReply.find(params[:id])
    @success = false
    @id = params[:id]
    if @message_reply.user == current_user
      if @message_reply.destroy
        @success = true
      else
        @success = false
      end
    else
      @success = false
    end
  end
end
