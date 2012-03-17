#coding : utf-8
class TimelineEntriesController < ApplicationController


	before_filter :authenticate_user!, :except => [:index,:list,:show,:entry]

  # GET /timeline_entries
  # GET /timeline_entries.json
  def index
		
		#[:start, :end, :unit, :pol1, :pol2]
	
		# politician (1 or 2)
		q_pol = nil
		if params[:pol1] and params[:pol2]
			q_pol = {:politician_id.in => [params[:pol1], params[:pol2]]}
			@politicians = Politician.find([params[:pol1], params[:pol2]])
		elsif params[:pol1]
			q_pol = {:politician_id => params[:pol1]}
			@politicians = Politician.find(params[:pol1])
		end

		# updated_at
		if params[:from]
			q_time = {:updated_at => {'$gte' => params[:from]}}
		elsif params[:after]
			q_time = {:updated_at => {'$gt' => params[:after]}}
		else
			q_time = {:deleted => false} # (all except deleted)
		end

	  @timeline_entries = TimelineEntry.where(q_time)
	 	@timeline_entries = @timeline_entries.where(q_pol) if q_pol 
	
		if @politicians.nil?
			@politicians = Politician.order_by(:name).limit(2)
			@timeline_entries = @timeline_entries.where(:politician_id.in =>[@politicians[0].id, @politicians[1].id])
		end

		@p1 = @politicians[0]
		@p2 = @politicians[1] if @politicians.length > 2

    respond_to do |format|
      #format.html # index.html.erb
      format.json { render json: @timeline_entries.to_json(:include => {:link_replies => {:only =>[:count]}}) }
    end
  end

  def list
    @entry = Politician.find(params[:id]).timeline_entries.page(params[:page]).per(3)
    @link = LinkReply.new
  end

  # GET /timeline_entries/1
  # GET /timeline_entries/1.json
  def show
    @timeline_entry = TimelineEntry.find(params[:id])
    @link_replies = @timeline_entry.link_replies.desc('created_at')
    @new_link = LinkReply.new

    @other_links = [] #TODO : 관련 링크 가져오기

    respond_to do |format|
      format.json { render json: @timeline_entry }
      format.html { render :layout => false }
    end
  end

  # GET /timeline_entries/new
  # GET /timeline_entries/new.json
  def new
    @timeline_entry = TimelineEntry.new
    @politician = Politician.find(params[:politician_id])
    @timeline_entry.politician = @politician
    @timeline_entry.preview = Preview.new

    respond_to do |format|
      format.html { render :layout => false }# new.html.erb
      format.json { render json: @timeline_entry }
    end
  end

  # GET /timeline_entries/1/edit
  def edit
    @timeline_entry = TimelineEntry.find(params[:id])
    @politician = @timeline_entry.politician
    render :layout => false
  end

  # POST /timeline_entries
  # POST /timeline_entries.json
  def create
    @timeline_entry = TimelineEntry.new(params[:timeline_entry])
    @timeline_entry.user_id = current_user.id
    @politician = @timeline_entry.politician

    @message = ""
    if @politician
      @politician.inc(:good_link_count, 1) if @timeline_entry.is_good
      @politician.inc(:bad_link_count, 1) unless @timeline_entry.is_good
    end

    if(params[:timeline_entry][:tweet])
      unless tweet_after_create
        @error = 1
        @message += "tweet을 게시하는데 오류가 발생했습니다."
      end
    end
    if(params[:timeline_entry][:facebook])
      unless post_after_create
        @error = 1
        @message += "facebook에 포스팅하는데 오류가 발생했습니다."
      end
    end

    respond_to do |format|
      if @timeline_entry.save
        if @error == 1
          format.html { redirect_to @timeline_entry, notice: 'Timeline entry was successfully created. SNS post error.' }
          format.json { render json: @timeline_entry, status: :created, location: @timeline_entry }
        else
          format.html {
           render json: @timeline_entry, status: :created, location: @timeline_entry
          }
          format.json {
           render json: @timeline_entry, status: :created, location: @timeline_entry
          }
        end
      else
        format.html { render action: "new" }
        format.json { render json: @timeline_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /timeline_entries/1
  # PUT /timeline_entries/1.json
  def update
  	
    @timeline_entry = TimelineEntry.find(params[:id],:user_id => current_user.id)
		# prevent updating from previous value
		params[:timeline_entry].delete :like_count
		params[:timeline_entry].delete :link_count

    respond_to do |format|
      if @timeline_entry.update_attributes(params[:timeline_entry])
        format.html { redirect_to @timeline_entry, notice: 'Timeline entry was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @timeline_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /timeline_entries/1
  # DELETE /timeline_entries/1.json
  def destroy
    @timeline_entry = TimelineEntry.find(params[:id],:user_id => current_user.id)
    # rather than @timeline_entry.destroy, we mark deleted
    @timeline_entry.deleted = true
    @timeline_entry.save

    respond_to do |format|
      format.html { redirect_to timeline_entries_url }
      format.json { head :no_content }
    end
  end

  def like
    @t = TimelineEntry.find(params[:id])
    @result = @t.like(current_user)
    @timeline_entry = @t
  end

  def blame
    @t = TimelineEntry.find(params[:id])
    @result = @t.blame(current_user)
    @timeline_entry = @t
  end
  
	def entry
    @link = LinkReply.new 
    @entry = TimelineEntry.find(params[:id])
    @entry.preview = Preview.where(:url => @entry.url).first
    render :partial => "timeline_entry", :locals => {:timeline_entry => @entry}, :layout => false
  end


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
        Twitter.update(params[:timeline_entry][:title]+" http://wepoll.or.kr"+display_timeline_entry_path(@timeline_entry.id)+" \nhttp://wepoll.or.kr 에서 등록")
        true
      rescue Twitter::Error => e
        Rails.logger.info "Tiwtter tweet error"
        puts "Tiwtter tweet error"
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
        Rails.logger.info "페이스북포스팅중, 정치인 이름은 #{@politician.name} "
        @graph.put_object("me","feed",:message => params[:timeline_entry][:title], :link => "http://wepoll.or.kr"+display_timeline_entry_path(@timeline_entry.id), :picture => "http://wepoll.or.kr"+@politician.profile_photo(:square100), :description => "위폴 "+@politician.name+"의 "+((params[:is_good]==true) ? "칭찬" : "지적") +"링크를 등록하셨습니다." )
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
end
