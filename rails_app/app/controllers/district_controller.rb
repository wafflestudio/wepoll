#coding:utf-8
class DistrictController < ApplicationController
  before_filter :simplify_district_name
  def show
    politicians = Politician.where(:district => @district)
    raise "#{@district} 후보 수 != 2" if politicians.count != 2
    @p1 = politicians.first
    @p2 = politicians.last

    p1_bill_categories = @p1.initiate_bills_categories
    p2_bill_categories = @p2.initiate_bills_categories

    @p1_bill_counts = p1_bill_categories.values
    @p1_bill_categories = p1_bill_categories.keys

    @p2_bill_counts = p2_bill_categories.values
    @p2_bill_categories = p2_bill_categories.keys
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
