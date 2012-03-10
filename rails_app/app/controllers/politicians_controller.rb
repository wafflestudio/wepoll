class PoliticiansController < ApplicationController
  before_filter :prepare_politicians, :except => [:initiate_bills]
  def initiate_bills
    @politician = Politician.find(params[:id])

    @bills = @politician.initiate_bills.page(params[:page]).per(8)

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

    render :layout => false
  end

  def profile
    render :layout => false
  end

  def promises
    @promises = @politicians.map{|p| p.promises[0...3]}
    render :layout => false
  end

  protected
  def prepare_politicians
    @politicians = [Politician.find(params[:id1]), Politician.find(params[:id2])]
  end
end
