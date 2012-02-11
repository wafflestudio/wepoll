class Admin::BillsController < Admin::AdminController
  def index
    @bills = Bill.page(params[:page]).per(20)
  end

  def show
    @bill = Bill.find(params[:id])
    @keys = Bill.fields.keys.reject {|k| k.index("_") || k =~ /ids$/}
  end
end
