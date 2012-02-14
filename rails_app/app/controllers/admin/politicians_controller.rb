class Admin::PoliticiansController < Admin::AdminController
  #XXX : for just debugging or external test connection
  #Be sure that remove this line for production
  skip_before_filter :is_admin?

  def index
    @politicians = Politician.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.json do
#        render_options = {:json => {:data => @politicians, :pages => @politicians.page.num_pages , :current => @politicians.current_page }.to_json, :only => [:_id, :name]}
        if params[:callback]
          render :json => {:data => @politicians ,
            :pages => @politicians.page.num_pages,
            :current => @politicians.current_page}.to_json(:except => [:profile_photo_content_type, :profile_photo_file_name, :profile_photo_updated_at, :profile_photo_file_size, :bill_ids]), :callback => params[:callback]
        else
          render :json => {:data => @politicians,
            :pages => @politicians.page.num_pages,
            :current => @politicians.current_page}.to_json(:except => [:profile_photo_content_type, :profile_photo_file_name, :profile_photo_updated_at, :profile_photo_file_size, :bill_ids])
        end
      end
    end
  end

  def show
    @politician = Politician.find(params[:id])
    @keys = Politician.fields.keys.reject {|k| k.index("_") || k =~ /id$/}

    respond_to do |format|
      format.html
      format.json do
        if params[:callback]
          render :json => @politician, :callback => params[:callback]
        else
          render :json => @politician
        end
      end
    end
  end

  def search
    @politicians = Politician.find(:all, :conditions => {:name => /#{params[:query]}/}).page(params[:page]).per(20)
    Rails.logger.info @politicians.count

    respond_to do |format|
      format.html {render :action => 'index'}
      format.js {render :json => @politicians.to_json(:only => [:_id, :name, :party])}
    end
  end
end
