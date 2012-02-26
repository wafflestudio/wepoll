class Admin::BillsController < Admin::AdminController
  #XXX : for just debugging or external test connection
  #Be sure that remove this line for production
  skip_before_filter :is_admin?

  def index
    @bills = Bill.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.json do
        if params[:callback]
          render :json =>  {:data => @bills,
           :pages => @bills.page.num_pages,
          :current => @bills.current_page}.to_json, :callback => params[:callback]
        else
          render :json =>  {:data => @bills,
           :pages => @bills.page.num_pages,
          :current => @bills.current_page}.to_json
        end
      end
    end
  end

  def show
    @bill = Bill.find(params[:id])
    @keys = Bill.fields.keys.reject {|k| k =~ /^_/ || k =~ /id[s]?$/ || k == 'summary'}

    respond_to do |format|
      format.html
      format.json do
        if params[:callback]
          render :json => @bill, :callback => params[:callback]
        else
          render :json => @bill
        end
      end
    end
  end

  def new
    @bill = Bill.new
  end

  def create
    params[:bill][:tags] = params[:bill_tags].split(",").map {|t| t.strip}.reject {|t| t.length == 0}
    params[:bill][:coactor_ids] = params[:bill][:coactor_ids].split(",")
    params[:bill][:supporter_ids] = params[:bill][:coactor_ids].split(",")
    params[:bill][:dissenter_ids] = params[:bill][:coactor_ids].split(",")
    @bill = Bill.new(params[:bill])

    if @bill.save
      redirect_to admin_bill_path(@bill)
    else
      render new_admin_bill_path
    end

  end

  def edit
    @bill = Bill.find(params[:id])
    @initiator = @bill.initiator
    @coactors = @bill.coactors
    @supporters = @bill.supporters
    @dissenters = @bill.dissenters
  end

  def update
    params[:bill][:tags] = params[:bill_tags].split(",").map {|t| t.strip}.reject {|t| t.length == 0}
    params[:bill][:coactor_ids] = params[:bill][:coactor_ids].split(",")
    params[:bill][:supporter_ids] = params[:bill][:coactor_ids].split(",")
    params[:bill][:dissenter_ids] = params[:bill][:coactor_ids].split(",")
    @bill = Bill.find(params[:id])
    if @bill.update_attributes(params[:bill])
      redirect_to admin_bill_path(@bill)
    else
      render edit_admin_bill_path(@bill)
    end
  end

  def search
    @bills = Bill.find(:all, :conditions => {:title => /#{params[:query]}/}).page(params[:page]).per(20)
    render :action => 'index'
  end
end
