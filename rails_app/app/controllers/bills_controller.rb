class BillsController < ApplicationController
  layout false
 
 	# GET /bills
  # GET /bills.json
  def index
  	if params[:for_timeline]
			@bills = Bill.where(:initiator_id.in => params[:politicians]).where(:complete =>true).limit(10)
		else
	  	@bills = Bill.all.limit(10)
  	end

    respond_to do |format|
      format.json { render json: @bills.to_json(:include => {:initiator => {:only =>[:name]}}) }
    end

  end


	# GET /bills/1
  # GET /bills/1.json
  def show
    @bill = Bill.find(params[:id])
	  respond_to do |format|
      format.json { render json: @bill}
      format.html 
    end
  end
end
