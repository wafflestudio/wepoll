# encoding: utf-8
require 'oauth2'
require 'csv'
class MainController < ApplicationController
  before_filter :before_search
  def index
    @politicians = Politician.all.asc('name').limit(10)
  end

  # XXX:for just debugging!
  def facebook_test
    @oauth= Koala::Facebook::OAuth.new(FACEBOOK_CLIENT[:key], FACEBOOK_CLIENT[:secret], "http://choco.wafflestudio.net:3082/main/fb_test_callback")
    redirect_to @oauth.url_for_oauth_code(:permissions=>"email, read_stream, publish_stream")
#    oauth_client = OAuth2::Client.new(FACEBOOK_CLIENT[:key], FACEBOOK_CLIENT[:secret], {
#      :authorize_url => 'https://www.facebook.com/dialog/oauth'
#    })
#
#    redirect_to oauth_client.authorize_url({
#      :client_id => FACEBOOK_CLIENT[:key],
#      :redirect_uri => "http://choco.wafflestudio.net:3082/main/fb_test_callback/",
#      :scope => 'email,read_stream,publish_stream'
#    })
  end

  def facebook_test_callback
    @oauth= Koala::Facebook::OAuth.new(FACEBOOK_CLIENT[:key], FACEBOOK_CLIENT[:secret], "http://choco.wafflestudio.net:3082/main/fb_test_callback")
    token = @oauth.get_access_token(params[:code])
#    client = OAuth2::Client.new(FACEBOOK_CLIENT[:key],
#                                FACEBOOK_CLIENT[:secret],
#                                :token_url => '/oauth/access_token',
#                                :site => 'https://graph.facebook.com')
#    @oauth = Koala::Facebook::OAuth.new(FACEBOOK_CLIENT[:key],FACEBOOK_CLIENT[:secret], "http://choco.wafflestudio.net:3082/main/fb_test_callback")
    #token = @oauth.get_access_token(params[:code])
#      token = client.get_token(:client_id => FACEBOOK_CLIENT[:key],
#                               :client_secret => FACEBOOK_CLIENT[:secret],
#                               :code => params[:code],
#                               :redirect_uri => "http://choco.wafflestudio.net:3082/main/fb_test_callback/")
      @graph = Koala::Facebook::API.new(token)
      @graph.put_object("me","feed",:message => 'post')


#      token.post("/#{current_user.facebook_token.uid}/feed?access_token=#{token.token}&message=hihi", :message => "hihi", :link => 'http://google.com')
      render :text => 'hello'


  end


  def forum
    @politician = Politician.find(params[:politician_id])
    @best = @politician.tweets.desc('recommend_count').first
    @today_best = @politician.tweets.desc('today_recommend_count').first
    @links = TimelineEntry.asc('like')
  end

  def before_search
    @source = Array.new

    CSV.foreach(Rails.root + "district.csv", :encoding => "UTF-8") do |csv|
      ## type
        # 0 : district
        # 1 : name
        # 2 : dong
      ##

      # district
      data = csv[0]
      party = ""
      type = "0"
      label = data
      @source << "{'data':'#{data}','party':'#{party}','type':'#{type}','label':'#{label}'}".html_safe

      # name
      data = csv[1]
      party = csv[2]
      type = "1"
      label = "#{data}(#{party})"
      @source << "{'data':'#{data}','party':'#{party}','type':'#{type}','label':'#{label}'}".html_safe

      # dong
      type = "2"
      party = csv[0]
      csv[3].split(" ").each do |dong|
        data = dong
        label = data 
        @source << "{'data':'#{data}','party':'#{party}','type':'#{type}','label':'#{label}'}".html_safe
      end
    end
  end

  def search
    Rails.logger.info "======================"
    Rails.logger.info params.inspect
    Rails.logger.info "======================"
    type = params[:query_type].to_i # 0 : 지역구, 1 : 국회의원, 2 : 동
    query = params[:query].sub(" ","")
    sub_query = params[:query_hidden].sub(" ","") # 국회의원일 경우 당이 따라옴. 동일 경우에는 지역구가 따라옴
    id = params[:query_id]

    if type == 0
      @politician = Politician.where(district: sub_query).first
    elsif type == 1
      @politician = Politician.find(sub_query)
    else
      @politician = Politician.where(district: sub_query).first
    end

    if !@politician.nil?
      redirect_to forum_path(@politician._id)
    else
      flash[:search] = "'#{params[:query]}'에 대한 검색 결과가 없습니다"
      redirect_to root_url 
      #redirect_to back
    end
  end

  def vs_district
    @politicians = Politician.where(:district => params[:district_name]) #params[:district_name] should be normalized
    #TODO : serialize only intersted items
    render :json => @politicians
  end
end
