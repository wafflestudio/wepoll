class BillsController < ApplicationController
  layout false
  def show
    @bill = Bill.find(params[:id])
    render :layout => false
  end
end
