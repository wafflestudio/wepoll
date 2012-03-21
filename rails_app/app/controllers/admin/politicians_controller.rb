#coding: utf-8
require 'yaml'
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

  def new
    @politician = Politician.new
  end

  def edit
    @politician = Politician.find(params[:id])
  end

  def update
    params[:politician][:district] = "" if params[:politician][:district] == "없음"
    params[:politician][:elections] = params[:politician][:elections].split(",").map {|e| e.to_i}
    params[:politician][:promises] = YAML::load params[:promises]
    #XXX : elections가 확정적이 되면 이 필드는 필요없다
    params[:politician][:election_count] = params[:politician][:elections].count
    @politician = Politician.find(params[:id])

    if @politician.update_attributes(params[:politician])
      redirect_to admin_politician_path(@politician)
    else
      render edit_admin_politician_path(@politician)
    end
  end

  def create
    params[:politician][:district] = "" if params[:politician][:district] == "없음"
    params[:politician][:elections] = params[:politician][:elections].split(",").map {|e| e.to_i}
    params[:politician][:promises] = YAML::load params[:promises]
    #XXX : elections가 확정적이 되면 이 필드는 필요없다
    params[:politician][:election_count] = params[:politician][:elections].count
    @politician = Politician.new(params[:politician])

    if @politician.save
      redirect_to admin_politician_path(@politician)
    else
      render new_admin_politician_path
    end
  end

  def destroy
    @politician = Politician.find(params[:id])
    @politician.destroy
    redirect_to admin_politicians_path
  end

  def search
    @politicians = Politician.find(:all, :conditions => {:name => /#{params[:query]}/}).page(params[:page]).per(20)
    Rails.logger.info @politicians.count

    respond_to do |format|
      format.html {render :action => 'index'}
      format.js {render :json => @politicians.to_json(:only => [:_id, :name, :party])}
    end
  end

  def upload_photo
    tmp_file_name = (0...8).map{ ('a'..'z').to_a[rand(26)] }.join + "_" + Time.now.to_i.to_s
    #convert
    Rails.logger.info %x[convert #{params[:data].path} -format jpg #{Rails.root + "public/#{tmp_file_name}.jpg"}]
#    FileUtils.copy(params[:data].path, Rails.root + "public/" + tmp_file_name)
    FileUtils.copy(Paperclip::Thumbnail.new(File.open(Rails.root + "public/#{tmp_file_name}.jpg"), :geometry => params[:geometry], :format => 'jpg').make, Rails.root + "public/" + "#{tmp_file_name}_thumb.jpg")
File.open(Rails.root+"public/#{tmp_file_name}.jpg").chmod 0555
File.open(Rails.root+"public/#{tmp_file_name}_thumb.jpg").chmod 0555
    render :text => {:file_name => tmp_file_name+".jpg", :thumb_url => "/#{tmp_file_name}_thumb.jpg"}.to_json
  end
end
