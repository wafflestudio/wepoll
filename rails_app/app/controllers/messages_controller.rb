class MessagesController < ApplicationController

	def index
		@messages = Message.all

	end

	def new
		@message = Message.new

	end

	def create
		@message = Message.new(params[:message])
		if @message.save

		else

		end
	end

	def update

	end

	def show
		@message = Message.find(params[:id])

	end

	def destroy

	end

end
