#coding: utf-8
class MessagesController < ApplicationController

	before_filter :authenticate_user!, :except => [:index, :new, :show]

	def index
		@messages = Message.all

	end

	def new
		@message = Message.new

	end

	def create
		@message = Message.new(params[:message])
		@message.user_id = current_user.id

		if params[:parent_message_id] != nil
			@parent_message = Message.find(params[:parent_message_id])
			@parent_message.replies << @message
			@message.parent_message = @parent_message
		end


		if @message.save
			 
		else

		end

		respond_to do |format|
			format.json {render json: @message.to_json}
		end
	end

	def update

	end

	def show
		@message = Message.find(params[:id])

	end

	def destroy

	end


  #begin protected

protected
  def tweet_after_create
    if current_user.twitter_token
      Twitter.configure do |config|
        config.consumer_key = TWITTER_CLIENT[:key]
        config.consumer_secret = TWITTER_CLIENT[:secret]
        config.oauth_token = current_user.twitter_token.access_token
        config.oauth_token_secret  = current_user.twitter_token.access_token_secret
      end

      begin
        Twitter.update(params[:message][:body]+" http://wepoll.or.kr"+message_path(@message.id)+" \nhttp://wepoll.or.kr 에서 등록")
        true
      rescue Twitter::Error => e
        Rails.logger.info "Twitter tweet error"
        puts "Twitter tweet error"
        Rails.logger.info e.message
        puts e.message
        false
      end
    else
      Rails.logger.info "twitter token doesn't exist"
      puts "twitter token doesn't exist"
      false
    end
  end

  def post_after_create
    @facebook_cookies ||= Koala::Facebook::OAuth.new(FACEBOOK_CLIENT[:key], FACEBOOK_CLIENT[:secret]).get_user_info_from_cookie(cookies)
    unless @facebook_cookies.nil?
      begin
        @access_token = @facebook_cookies["access_token"]
        @graph = Koala::Facebook::GraphAPI.new(@access_token)
        Rails.logger.info "페이스북 포스팅중, 정치인 이름은 #{@politician.name} "
        @graph.put_object("me","feed",:message => params[:message][:body], :link => "http://wepoll.or.kr"+message_path(@message.id), :picture => "http://wepoll.or.kr"+@politician.profile_photo(:square100), :description => "위폴 "+@politician.name+"에게 메세지를 등록하셨습니다." )
        true
      rescue StandardError => e
        Rails.logger.info e.message
        puts e.message
      end
    else
      Rails.logger.info "facebook cookie doesn't exist"
      puts "facebook cookie doesn't exist"
      false
    end
  end

  ## end of protected

end
