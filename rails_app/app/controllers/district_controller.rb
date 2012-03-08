#coding:utf-8
class DistrictController < ApplicationController
  before_filter :simplify_district_name
  def show
    @politicians = Politician.where(:district => @district).desc(:good_link_count)

    if @politicians.count < 2
      render :json => []
      return
    end
    raise "politicians.count < 2" if @politicians.count < 2

    if (params[:p1_id] && params[:p2_id])
      @p1 = @politicians.where(:_id => params[:p1_id]).first
      @p2 = @politicians.where(:_id => params[:p2_id]).first
    else
      @p1 = @politicians[0]
      @p2 = @politicians[1]
    end

    p1_bill_categories = @p1.initiate_bills_categories
    p2_bill_categories = @p2.initiate_bills_categories

    @p1_bill_counts = p1_bill_categories.map {|c,n| n}
    @p1_bill_categories = p1_bill_categories.map {|c,n| c}

    @p2_bill_counts = p2_bill_categories.map {|c,n| n}
    @p2_bill_categories = p2_bill_categories.map {|c,n| c}

    @other_politicians = @politicians.reject {|p| p == @p1 || p==@p2}

    @t1 = @p1.tweets.asc('created_at').first
    @t2 = @p2.tweets.asc('created_at').first

		# Timeline => See timeline_controller.rb.
		if params[:from]
			q_time = {:updated_at => {'$gte' => params[:from]}}
		elsif params[:after]
			q_time = {:updated_at => {'$gt' => params[:after]}}
		else
			q_time = {:deleted => false} # (all except deleted)
		end

	  @timeline_entries = TimelineEntry.where(q_time).where(:politician_id.in => [@p1.id,@p2.id])


    respond_to do |format|
      format.html
      format.js {render :json => [@p1, @p2], :only => [:name, :party, :district, :good_link_count, :bad_link_count, :_id]}
    end
  end

  protected
  def simplify_district_name
    if !params[:name].nil?
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
