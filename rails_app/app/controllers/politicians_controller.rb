#coding:utf-8
class PoliticiansController < ApplicationController
  before_filter :prepare_politicians, :except => [:initiate_bills]
  def initiate_bills
    @politician = Politician.find(params[:id])
    if params[:result]
      @bills = @politician.initiate_bills.where(:result => Bill::RESULT_APPROVED).page(params[:page]).per(8)
    else
      @bills = @politician.initiate_bills.page(params[:page]).per(8)
    end

    respond_to do |format|
      format.html do 
        @bill_categories = @politician.initiate_bills_categories
      end
      format.js {}
    end
    render :layout => false
  end

  def bill_activities
    bill_categories = @politicians.map {|p| p.initiate_bills_categories}

    @bill_counts = bill_categories.map {|bc| bc.map {|c,n| n}}
    @bill_categories = bill_categories.map {|bc| bc.map {|c,n| "#{c} #{n}"}}
    @party_color = {"자유선진당" => "#007DC5", "통합진보당" => "#6F0086", "무소속" =>"#4F4F50","진보신당" => "#f5314f" }

    render :layout => false
  end

  def profile
    render :layout => false
  end

  def promises
    @promises = @politicians.map{|p| p.promises[0...3]}
    render :layout => false
  end

  def recent_links
    @link = LinkReply.new 
    render :layout => false
  end

  def popular_links
    @link = LinkReply.new 
    render :layout => false
  end

  protected
  def prepare_politicians
    @politicians = [Politician.find(params[:id1]), Politician.find(params[:id2])]
  end
end
