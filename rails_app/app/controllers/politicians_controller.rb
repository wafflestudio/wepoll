#coding:utf-8
class PoliticiansController < ApplicationController

  before_filter :prepare_politicians, :except => [:initiate_bills, :popular_links, :recent_links]

  def initiate_bills
    @age = params[:age].to_i
    @politician = Politician.find(params[:id])
    if params[:result]
      @bills = @politician.initiate_bills.where(:result => '가결').where(:age => @age).page(params[:page]).per(8)
    else
      @bills = @politician.initiate_bills.page(params[:page]).where(:age => @age).per(8)
    end

    respond_to do |format|
      format.html do 
        @bill_categories = @politician.initiate_bills_categories(@age)
      end
      format.js {}
    end
    render :layout => false
  end

  def bill_activities
    @ages = @politicians.map {|p| p.elections.sort {|x,y| y<=>x}.first}
    c = -1
    bill_categories = @politicians.map {|p| p.initiate_bills_categories(@ages[c+=1])}

    @bill_counts = bill_categories.map {|bc| bc.map {|c,n| n}}
    @bill_categories = bill_categories.map {|bc| bc.map {|c,n| "#{c} #{n}"}}
    @party_color = {"자유선진" => "#007DC5", "통합진보" => "#6F0086", "무소속" =>"#4F4F50","진보신당" => "#f5314f", "민주통합" => "#257a01", "새누리당" => "#c2271e" }

    render :layout => false
  end

  def profile
    render :layout => false
  end

  def promises
    @promises = @politicians.map{|p| p.promises[0...3]}
    render :layout => false
  end

  def recent_links_tab
    @entries = @politicians.map {|p| p ? p.timeline_entries.desc("created_at").page(params[:page]).per(3) : []}
    @link = LinkReply.new 
    render :layout => false
  end

  def popular_links_tab
    @entries = @politicians.map {|p| p ? p.timeline_entries.desc("like_count", "created_at").page(params[:page]).per(3) : []}
    @link = LinkReply.new 
    render :layout => false
  end

  def votes_for_issues_tab
    numbers = ["1803016","1803009","1803214","1803199","1803211","1804008","1806667","1806972","1807336","1807413","1807946","1808656","1809861","1810023","1810176","1811438","1811597","1811651","1812142","1814644","1814645"]
    @bills = Bill.where(:number.in => numbers)
    @votes_by_politicians = VoteForBillByPolitician.any_in(:politician_id => [@politicians[0].id,@politicians[1].id])
    @votes_by_parties = VoteForBillByParty.asc(:party)

    render :layout => false, :file => 'politicians/issueline'
  end

  def messages_tab
  	 @p1 = params[:id1]
  	 @p2 = params[:id2]
     @messages = Message.where(:politician_id.in => [params[:id1],params[:id2]]).desc("created_at").page(params[:page]).per(10)
     @message = Message.new
     render :layout => false
  end

  def messages
     @messages = Message.where(:politician_id.in => [params[:id],params[:id2]]).desc("created_at").page(params[:page]).per(10)
     @message = Message.new
     render :layout => false
  end

  def recent_links
    @link = LinkReply.new 
    @p = Politician.find(params[:id])
    @entries = @p.timeline_entries.desc("created_at").page(params[:page]).per(3)
    render :layout => false
  end


  def popular_links
    @link = LinkReply.new 
    @p = Politician.find(params[:id])
    @entries = @p.timeline_entries.desc("like_count", "created_at").page(params[:page]).per(3)

    render :layout => false
  end

  def link_counts
    if params[:id]
      @pol = Politician.find(params[:id])
      render :json => {:good_link_count => @pol.good_link_count , :bad_link_count => @pol.bad_link_count}
    elsif params[:district]
      @pol = Politician.where(:district => params[:district])
      render :json => @pol.to_json(:only => [:_id, :good_link_count, :bad_link_count])
    end
  end

  def initiate_bills_summary
    @politician = Politician.find(params[:id])
    @party_color = {"자유선진" => "#007DC5", "통합진보" => "#6F0086", "무소속" =>"#4F4F50","진보신당" => "#f5314f", "민주통합" => "#257a01", "새누리당" => "#c2271e" }
    @age = params[:age].to_i
    bill_categories = @politician.initiate_bills_categories(@age)
    @index = params[:index].to_i
    @bill_counts = bill_categories.map {|c,n| n}
    @bill_categories = bill_categories.map {|c,n| "#{c} #{n}"}
    Rails.logger.info @bill_categories.to_json
    render :layout => false
  end



  def top_joint_initiate_bills
    @politician = Politician.find(params[:id])
    @top_joint_initiate_bill_politicians = @politician.joint_initiate_bill_politicians[params[:age].to_i][0...4]
    @bill_count = @politician.initiate_bills.where(:age => params[:age].to_i).count
    render :layout => false
  end

  protected
  def prepare_politicians
    @politicians = [params[:id1] ? Politician.find(params[:id1]) : nil, params[:id2] ? Politician.find(params[:id2]) : nil]
  end

end
