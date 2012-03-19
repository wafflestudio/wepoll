#coding:utf-8
require 'iconv'
class DistrictController < ApplicationController
  before_filter :simplify_district_name
  before_filter :ready_politicians, :except => [:show_timeline_entry]
  def show
    respond_to do |format|
      format.html do
        #timeline bootstrap
        # Timeline => See timeline_controller.rb.
        if params[:from]
          q_time = {:updated_at => {'$gte' => params[:from]}}
        elsif params[:after]
          q_time = {:updated_at => {'$gt' => params[:after]}}
        else
          q_time = {:deleted => false} # (all except deleted)
        end
        @timeline_entries = TimelineEntry.where(q_time).where(:politician_id.in => [@p1,@p2].map {|p| p.nil? ? nil : p.id})
        @message = Message.new
      end
      format.js {render :json => [@p1, @p2], :only => [:name, :party, :district, :good_link_count, :bad_link_count, :_id]}
    end
  end

  def show_timeline_entry
    @politicians = Politician.where(:district => @district).where(:candidate => true).sort {|x,y| (y.good_link_count + y.bad_link_count) <=> (x.good_link_count + x.bad_link_count)}
    @party_color = {"자유선진" => "#007DC5", "통합진보" => "#6F0086", "무소속" =>"#4F4F50","진보신당" => "#f5314f", "민주통합" => "#257a01", "새누리당" => "#c2271e" }
    @timeline_entry = TimelineEntry.find(params[:timeline_entry_id])
    @p1 = @timeline_entry.politician
    @p2 = Politician.where(:district => @p1.district).reject {|p| p.id == @p1.id}.first
    p1_bill_categories = @p1.nil? ? [] : @p1.initiate_bills_categories
    p2_bill_categories = @p2.nil? ? [] : @p2.initiate_bills_categories

    @p1_bill_counts = p1_bill_categories.map {|c,n| n}
    @p1_bill_categories = p1_bill_categories.map {|c,n| c}

    @p2_bill_counts = p2_bill_categories.map {|c,n| n}
    @p2_bill_categories = p2_bill_categories.map {|c,n| c}

    @other_politicians = @politicians.reject {|p| p == @p1 || p==@p2}

    @t1 = @p1.nil? ? nil : @p1.tweets.desc('created_at').first
    @t2 = @p2.nil? ? nil : @p2.tweets.desc('created_at').first
    @tweets = [@t1, @t2]

    render :action => 'show'
  end

  protected
  def simplify_district_name
    Rails.logger.info "simplify_district_name"
    if !params[:name].nil?
      #      if request.env["HTTP_USER_AGENT"] =~ /MSIE/
      #	iconv = Iconv.new("UTF-8//IGNORE", "EUC-KR")
      begin
        params[:name] = params[:name].encode("UTF-8")
      rescue
      end
      #      end
      str = params[:name]
      redirect_to root_url if str == "undefined"
      if str && (%w(구 시).include? str[-2]) && (%w(갑 을 병 정 무 기 경 신 임 계).include? str[-1])
        if str.length-2 >= 2
          str = str[0...-2]+str[-1]
        end
      end
      @district = str
    elsif !params[:politician_id].nil?
      str = params[:politician_id].to_s
      if str == "undefined"
        redirect_to root_url
      else
        @p1 = Politician.find(str)
        @district = @p1.district
        redirect_to root_url if @district.empty?
      end
    elsif !params[:timeline_entry_id].nil?
      timeline_entry = TimelineEntry.find(params[:timeline_entry_id])
      @district = timeline_entry.politician.district
    end
  end

  def ready_politicians
    Rails.logger.info "district = " +@district
    @politicians = Politician.where(:district => @district).where(:candidate => true).sort {|x,y| (y.good_link_count + y.bad_link_count) <=> (x.good_link_count + x.bad_link_count)}
    @party_color = {"자유선진" => "#007DC5", "통합진보" => "#6F0086", "무소속" =>"#4F4F50","진보신당" => "#f5314f", "민주통합" => "#257a01", "새누리당" => "#c2271e" }
    if @politicians.count == 1
      @p1 = @politicians.first
    else
      if (params[:p1_id] && params[:p2_id])
        @p1 = @politicians.find {|p| p.id.to_s == params[:p1_id]}
        @p2 = @politicians.find {|p| p.id.to_s == params[:p2_id]}
      else
        if @p1.nil?
          @p1 = @politicians[0]
          @p2 = @politicians[1]
        else
          if @p1.id == @politicians[0].id
            @p2 = @politicians[1]
          else
            @p2 = @politicians[0]
          end
        end
      end
    end
    redirect_to district_politician_path(:politician_id => @p1.id) if @p1 == @p2

    p1_bill_categories = @p1.nil? ? [] : @p1.initiate_bills_categories
    p2_bill_categories = @p2.nil? ? [] : @p2.initiate_bills_categories

    @p1_bill_counts = p1_bill_categories.map {|c,n| n}
    @p1_bill_categories = p1_bill_categories.map {|c,n| c}

    @p2_bill_counts = p2_bill_categories.map {|c,n| n}
    @p2_bill_categories = p2_bill_categories.map {|c,n| c}

    @other_politicians = @politicians.reject {|p| p == @p1 || p==@p2}

    @t1 = @p1.nil? ? nil : @p1.tweets.desc('created_at').first
    @t2 = @p2.nil? ? nil : @p2.tweets.desc('created_at').first
    @tweets = [@t1, @t2]
  end
end
