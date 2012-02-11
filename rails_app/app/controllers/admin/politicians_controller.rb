class Admin::PoliticiansController < Admin::AdminController
  def index
    @politicians = Politician.page(params[:page]).per(20)
  end

  def show
    @politician = Politician.find(params[:id])
    @keys = Politician.fields.keys.reject {|k| k.index("_") || k =~ /id$/}
  end
end
