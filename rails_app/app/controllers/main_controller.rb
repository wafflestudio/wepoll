require 'oauth2'
require 'csv'

class MainController < ApplicationController
  def index
    @politicians = Politician.all.asc('name').limit(10)
  end

  # XXX:for just debugging!
  def facebook_test
    oauth_client = OAuth2::Client.new(FACEBOOK_CLIENT[:key], FACEBOOK_CLIENT[:secret], {
      :authorize_url => 'https://www.facebook.com/dialog/oauth'
    })

    redirect_to oauth_client.authorize_url({
      :client_id => FACEBOOK_CLIENT[:key],
      :redirect_uri => "http://ruby.snu.ac.kr:7789/main/fb_test_callback/",
      :scope => 'email,read_stream,publish_stream'
    })
  end

  def facebook_test_callback
    client = OAuth2::Client.new(FACEBOOK_CLIENT[:key],
                                FACEBOOK_CLIENT[:secret],
                                :token_url => '/oauth/access_token',
                                :site => 'https://graph.facebook.com')
      token = client.get_token(:client_id => FACEBOOK_CLIENT[:key],
                               :client_secret => FACEBOOK_CLIENT[:secret],
                               :code => params[:code],
                               :redirect_uri => "http://ruby.snu.ac.kr:7789/main/fb_test_callback/")
      @graph = Koala::Facebook::API.new(token.token)
      @graph.put_object("me","feed",:message => 'Using koala')


#      token.post("/#{current_user.facebook_token.uid}/feed?access_token=#{token.token}&message=hihi", :message => "hihi", :link => 'http://google.com')
      render :text => 'hello'


  end


  def forum
    @politician = Politician.find(params[:politician_id])
  end

  def search
    @query = params[:query]  
    @politician = Politician.where(name: @query).first
    if params[:search_pass] == "true" && !@politician.nil?
      redirect_to forum_path(@politician)
    else
      @district = Array.new
      @name = Array.new
      @dong = Array.new
      #@party = Array.new

      CSV.foreach(Rails.root + "district.csv", :encoding => "UTF-8") do |csv|
        if !csv[0].to_s.match(params[:query].to_s).nil?
#          @district << [csv[0], csv[1]]
#          @district << ["#{csv[0]}(#{csv[1]})"]
           @district << [csv[0]]
        end
        if !csv[1].to_s.match(params[:query].to_s).nil?
          #@name << [csv[1], csv[0]]
          #@name << ["#{csv[1]}(#{csv[0]})"]
          @name << [csv[1]]
        end
        csv[3].split(" ").each do |dong|
          if !dong.to_s.match(params[:query].to_s).nil?
            #@dong << [dong, csv[0], csv[1]]
            #@dong << ["#{dong}(#{csv[0]}, #{csv[1]})"]
            @dong << [dong]
          end
        end
      end
      if params[:search_pass] == "true"
        render "search"
      else
        respond_to do |format|
          format.html { render :layout => false }
          format.js
        end
      end
    end
  end
end
