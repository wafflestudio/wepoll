#coding: utf-8
class MessagesController < ApplicationController

	before_filter :authenticate_user!, :except => [:index, :new, :show]

  def list
    @entry = Message.find(params[:message_id])
    @replies = @entry.replies[0...@entry.replies.count - 3]
  end

	def index
		@messages = Message.all

	end

	def new
		@message = Message.new

	end

	def create
		@message = Message.new(params[:message])
    if params[:message][:politician_id] == "all"
      @message.politician_id = nil
      @message.politician = nil
    end
		@message.user_id = current_user.id
    @success = false

	
#		if params[:parent_message_id] != nil
#			@parent_message = Message.find(params[:parent_message_id])
#			@parent_message.replies << @message
#			@message.parent_message = @parent_message
#		end
		if @message.save
      @politician = @message.politician
      unless @politician.nil?
        @politician.inc(:message_count)
      end
      if params[:message][:tweet]
        @tweet = tweet_after_create
      end
      if params[:message][:facebook]
        @facebook = post_after_create
      end
      @success = true
		else
      @success = false
		end
	end

	def update

	end

	def show
		@message = Message.find(params[:id])

	end

	def destroy
    @message = Message.find(params[:id])
    @success = false
    @id = params[:id]
    if @message.user == current_user
      if @message.destroy
        @success = true
      else
        @success = false
      end
    else
      @success = false
    end
	end

  def like
    @message = Message.find(params[:id])
    if @message.like(current_user)
      render :json => {:status => "ok", :count => @message.like_count, :id => @message.id, :type => "like" }
    else
      render :json => {:status => "error", :message => "이미 추천하셨습니다."}
    end
  end
  def blame
    @message = Message.find(params[:id])
    if @message.blame(current_user)
      render :json => {:status => "ok", :count => @message.blame_count, :id => @message.id, :type => "blame" }
    else
      render :json => {:status => "error", :message => "이미 반대하셨습니다."}
    end
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
        if @politician.nil?
          path = district_name_path(message.district)
        else
          path = district_politician_path(@politician)
        end
        Twitter.update(params[:message][:body]+" http://wepoll.or.kr"+path+" \nhttp://wepoll.or.kr 에서 등록")
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
        if @politician.nil?
          path = district_name_path(@message.district)
          imgpath = "/btn_wepoll.gif"
          msg = "위폴에서 "+@message.district+"에 한마디를 등록하셨습니다." 
          Rails.logger.info "페이스북 포스팅중, 선거구는 #{@message.district} "
        else
          path = district_politician_path(@politician)
          imgpath = @politician.profile_photo.url(:square100)
          msg = "위폴에서 "+@message.district+" "+@politician.name+"에게 한마디를 등록하셨습니다."
          Rails.logger.info "페이스북 포스팅중, 정치인 이름은 #{@politician.name} "
        end
        Rails.logger.info imgpath
        Rails.logger.info "http://wepoll.or.kr"+imgpath
        @graph.put_object("me","feed",:message => params[:message][:body], :link => "http://wepoll.or.kr"+path, :picture => "http://wepoll.or.kr"+imgpath, :description => msg )
        true
      rescue StandardError => e
        Rails.logger.info "오류 발생"
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
