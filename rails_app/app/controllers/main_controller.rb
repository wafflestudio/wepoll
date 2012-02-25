# encoding: utf-8
require 'csv'
class MainController < ApplicationController
  before_filter :before_search
  def index
    @politicians = Politician.all.limit(10)
  end


  def forum
    @politician = Politician.find(params[:politician_id])
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
    type = params[:query_type].to_i # 0 : 지역구, 1 : 국회의원, 2 : 동
    query = params[:query].sub(" ","")
    sub_query = params[:query_party].sub(" ","") # 국회의원일 경우 당이 따라옴. 동일 경우에는 지역구가 따라옴
    id = params[:query_id]

    if type == 0
      @politician = Politician.where(district: query).first
    elsif type == 1
      @politician = Politician.where(name: query, party: sub_query).first
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
end
