#coding:utf-8
require 'iconv'
class DistrictController < ApplicationController
  before_filter :simplify_district_name
  def show
    @politicians = Politician.where(:district => @district).desc(:good_link_count)

    @party_color = {"자유선진당" => "#007DC5", "통합진보당" => "#6F0086", "무소속" =>"#4F4F50","진보신당" => "#f5314f", "민주통합당" => "#257a01", "새누리당" => "#c2271e" }

    if (params[:p1_id] && params[:p2_id])
      @p1 = @politicians.where(:_id => params[:p1_id]).first
      @p2 = @politicians.where(:_id => params[:p2_id]).first
    else
      @p1 = @politicians[0]
      @p2 = @politicians[1]
    end

    p1_bill_categories = @p1.nil? ? [] : @p1.initiate_bills_categories
    p2_bill_categories = @p2.nil? ? [] : @p2.initiate_bills_categories

    @p1_bill_counts = p1_bill_categories.map {|c,n| n}
    @p1_bill_categories = p1_bill_categories.map {|c,n| c}

    @p2_bill_counts = p2_bill_categories.map {|c,n| n}
    @p2_bill_categories = p2_bill_categories.map {|c,n| c}

    @other_politicians = @politicians.reject {|p| p == @p1 || p==@p2}

    @t1 = @p1.nil? ? nil : @p1.tweets.asc('created_at').first
    @t2 = @p2.nil? ? nil : @p2.tweets.asc('created_at').first
    @tweets = [@t1, @t2]


    # Timeline => See timeline_controller.rb.
    if params[:from]
      q_time = {:updated_at => {'$gte' => params[:from]}}
    elsif params[:after]
      q_time = {:updated_at => {'$gt' => params[:after]}}
    else
      q_time = {:deleted => false} # (all except deleted)
    end

    @timeline_entries = TimelineEntry.where(q_time).where(:politician_id.in => [@p1,@p2].map {|p| p.nil? ? nil : p.id})

    respond_to do |format|
      format.html
      format.js {render :json => [@p1, @p2], :only => [:name, :party, :district, :good_link_count, :bad_link_count, :_id]}
    end
  end

  def show_timeline_entry

    @timeline_entry = TimelineEntry.find(params[:id])
    @p1 = @timeline_entry.politician
    @p2 = Politician.where(:district => @p1.district).reject {|p| p.id == @p1.id}.first

    redirect_to district_vs_politicians_path(:p1_id => @p1.id, :p2_id => @p2.id, :timeline_entry_id => params[:id], :name => @p1.district)
  end

  protected
  def simplify_district_name
    if !params[:name].nil?
      if request.env["HTTP_USER_AGENT"] =~ /MSIE/
        iconv = Iconv.new("UTF-8", "EUC-KR")
        begin
          params[:name] = iconv.iconv(params[:name])
        rescue
          #do nothing
        end
      end
      Rails.logger.info params[:name]
      str = params[:name]
      if str && (%w(구 시).include? str[-2]) && (%w(갑 을 병 정 무 기 경 신 임 계).include? str[-1])
        if str.length-2 >= 2
          str = str[0...-2]+str[-1]
        end
      end
      @district = str
    elsif !params[:politician_id].nil?
      p = Politician.find(params[:politician_id])
      @district = p.district
    end
  end
end
