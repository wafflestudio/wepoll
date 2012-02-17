require 'csv'

class MainController < ApplicationController
  def index
    @politicians = Politician.all.limit(10)
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
          @district << [csv[0], csv[1]]
        end
        if !csv[1].to_s.match(params[:query].to_s).nil?
          @name << [csv[1], csv[0]]
        end
        csv[3].split(" ").each do |dong|
          if !dong.to_s.match(params[:query].to_s).nil?
            @dong << [dong, csv[0], csv[1]]
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
