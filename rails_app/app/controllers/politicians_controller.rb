#coding:utf-8
class PoliticiansController < ApplicationController
  before_filter :prepare_politicians, :except => [:initiate_bills, :popular_links, :recent_links]
  def initiate_bills
    @politician = Politician.find(params[:id])
    if params[:result]
      @bills = @politician.initiate_bills.where(:result => Bill::RESULT_APPROVED).where(:age => params[:age]).page(params[:page]).per(8)
    else
      @bills = @politician.initiate_bills.page(params[:page]).where(:age => params[:age]).per(8)
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
    @party_color = {"자유선진" => "#007DC5", "통합진보" => "#6F0086", "무소속" =>"#4F4F50","진보신당" => "#f5314f", "민주통합" => "#257a01", "새누리당" => "#c2271e" }

    render :layout => false
  end

  def profile
    render :layout => false
  end

  def promises
    @promises = @politicians.map{|p| p.promises[0...3]}
    render :layout => false
  end

  def recent_links_tab
    @entries = @politicians.map {|p| p ? p.timeline_entries.desc("created_at").page(params[:page]).per(3) : []}
    @link = LinkReply.new 
    render :layout => false
  end

  def popular_links_tab
    @entries = @politicians.map {|p| p ? p.timeline_entries.desc("like_count", "created_at").page(params[:page]).per(3) : []}
    @link = LinkReply.new 
    render :layout => false
  end

  def recent_links
    @link = LinkReply.new 
    @p = Politician.find(params[:id])
    @entries = @p.timeline_entries.desc("created_at").page(params[:page]).per(3)
    render :layout => false
  end

  def popular_links
    @link = LinkReply.new 
    @p = Politician.find(params[:id])
    @entries = @p.timeline_entries.desc("like_count", "created_at").page(params[:page]).per(3)

    render :layout => false
  end

  def link_counts
    if params[:id]
      @pol = Politician.find(params[:id])
      render :json => {:good_link_count => @pol.good_link_count , :bad_link_count => @pol.bad_link_count}
    elsif params[:district]
      @pol = Politician.where(:district => params[:district])
      render :json => @pol.to_json(:only => [:_id, :good_link_count, :bad_link_count])
    end
  end

  protected
  def prepare_politicians
    @politicians = [params[:id1] ? Politician.find(params[:id1]) : nil, params[:id2] ? Politician.find(params[:id2]) : nil]
  end
end
