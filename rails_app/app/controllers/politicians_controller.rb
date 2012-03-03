class PoliticiansController < ApplicationController
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
    @politician = Politician.find(params[:id])
    bill_categories = @politician.initiate_bills_categories
    @bill_counts = bill_categories.map {|c,n| n}
    @bill_categories = bill_categories.map {|c,n| c}
    render :layout => false
  end

  def profile
    @politician = Politician.find(params[:id])
    render :layout => false
  end

  def promises
    @politician = Politician.find(params[:id])
    @promises = @politician.promises[0...3]
    render :layout => false
  end
end
