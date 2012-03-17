# encoding: utf-8
require 'oauth2'
require 'csv'
class MainController < ApplicationController
layout false, :only => [:provision, :privacy]
  def index
    if !user_signed_in?
      sign_in_and_redirect User.first, {:event => :authentication}
    end
    @politicians = Politician.all.asc('name').limit(10)
    @big_header = true
  end

  def search
    Rails.logger.info "======================"
    Rails.logger.info params.inspect
    Rails.logger.info "======================"
    type = params[:query_type].to_i # 0 : 지역구, 1 : 국회의원, 2 : 동
    query = params[:query].sub(" ","")
    sub_query = params[:query_hidden].sub(" ","") # 국회의원일 경우 당이 따라옴. 동일 경우에는 지역구가 따라옴
    id = params[:query_id]

    if type == 0 && !sub_query.empty?
      @politician = Politician.where(district: sub_query).first
	elsif type == 1
@politician = Politician.find(sub_query)
	else
	if !sub_query.empty?
	@politician = Politician.where(district: sub_query).first
	else
	@politician = nil
	end
    end

    if !@politician.nil?
      if type != 1
        redirect_to district_name_path(sub_query)
      else
        redirect_to district_politician_path(@politician._id)
      end
    else
      flash[:search] = "'#{params[:query]}'에 대한 검색 결과가 없습니다"
      flash[:search_error] = "true"
      redirect_to back
    end
  end

  def vs_district
    @politicians = Politician.where(:district => params[:district_name]) #params[:district_name] should be normalized
    #TODO : serialize only intersted items
    render :json => @politicians
  end
end
