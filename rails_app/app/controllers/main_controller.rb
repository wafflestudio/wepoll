require 'oauth2'
class MainController < ApplicationController
  def index
    @politicians = Politician.all.limit(10)
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
    begin
      token = client.get_token(:client_id => FACEBOOK_CLIENT[:key],
                               :client_secret => FACEBOOK_CLIENT[:secret],
                               :code => params[:code],
                               :redirect_uri => "http://ruby.snu.ac.kr:7789/main/fb_test_callback/")
      token.post("/#{current_user.facebook_token.uid}/feed?access_token=#{token.token}&message=hihi", :message => "hihi", :link => 'http://google.com')
      render :text => 'hello'

    rescue OAuth2::Error => e
      Rails.logger.info "========"
      Rails.logger.info e.response.body
      Rails.logger.info "========"
      raise e
    end
  end


  def forum
    @politician = Politician.find(params[:politician_id])
  end

end
