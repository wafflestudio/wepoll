#coding:utf-8
class Admin::AdminController < ApplicationController
  before_filter :is_admin?

  layout 'admin'

  def index #dashboard
    'Dashboard here'
  end

  def new_admin
  end

  def create_admin
    if params[:password] != params[:password_confirm]
      render :js => "alert('패스워드가 일치하지 않습니다.')"
      return
    end
    admins = []
    begin
      f = File.open(Rails.root+"config/admin.yml","r")
      admins = YAML::load f.read
      f.close
    rescue
    end

    salt = [Array.new(8){rand(256).chr}.join].pack('m').chomp
    hash = Digest::SHA512.hexdigest(params[:password] + salt)
    new_admin = {:id => params[:admin_id], :password_salt => salt, :password_hash => hash}

    admins << new_admin

    f = File.open(Rails.root+"config/admin.yml", "w")
    f.write YAML::dump admins
    f.close

    redirect_to admin_path
  end

  protected
  def init_session(admin_id)
    session[:admin] = admin_id
  end

  def is_admin?
    if session[:admin].nil?
      flash[:warning] = "Login first"
      redirect_to admin_login_path
      false
    else
      true
    end
  end
end
