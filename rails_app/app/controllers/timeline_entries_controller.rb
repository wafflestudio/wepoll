class TimelineEntriesController < ApplicationController
  
	before_filter :authenticate_user!, :except => [:index,:show]
  
  # GET /timeline_entries
  # GET /timeline_entries.json
  def index
		
		#[:start, :end, :unit, :pol1, :pol2]
	
		# politician (1 or 2)
		q_pol = nil
		if params[:pol1] and params[:pol2]
			q_pol = {:politician_id.in => [params[:pol1], params[:pol2]]}
			@politicians = Politician.find([params[:pol1], params[:pol2]])
		elsif params[:pol1]
			q_pol = {:politician_id => params[:pol1]}
			@politicians = Politician.find(params[:pol1])
		end

		# updated_at
		if params[:from]
			q_time = {:updated_at => {'$gte' => params[:from]}}
		elsif params[:after]
			q_time = {:updated_at => {'$gt' => params[:after]}}
		else
			q_time = {:deleted => false} # (all except deleted)
		end

	  @timeline_entries = TimelineEntry.where(q_time)
	 	@timeline_entries = @timeline_entries.where(q_pol) if q_pol 
	
		if @politicians.nil?
			@politicians = Politician.order_by(:name).limit(2)
			@timeline_entries = @timeline_entries.where(:politician_id.in =>[@politicians[0].id, @politicians[1].id])
		end

		@p1 = @politicians[0]
		@p2 = @politicians[1] if @politicians.length > 2

    respond_to do |format|
      #format.html # index.html.erb
      format.json { render json: @timeline_entries }
    end
  end

  # GET /timeline_entries/1
  # GET /timeline_entries/1.json
  def show
    @timeline_entry = TimelineEntry.find(params[:id])

    respond_to do |format|
      format.json { render json: @timeline_entry }
    end
  end

  # GET /timeline_entries/new
  # GET /timeline_entries/new.json
  def new
    @timeline_entry = TimelineEntry.new
    @politician = Politician.find(params[:politician_id])

    respond_to do |format|
      format.html { render :layout => false }# new.html.erb
      format.json { render json: @timeline_entry }
    end
  end

  # GET /timeline_entries/1/edit
  def edit
    @timeline_entry = TimelineEntry.find(params[:id])
    render :layout => false
  end

  # POST /timeline_entries
  # POST /timeline_entries.json
  def create
    @timeline_entry = TimelineEntry.new(params[:timeline_entry], :user_id => current_user.id)
    politician = @timeline_entry.politician
    if politician
      politician.inc(:good_link_count, 1) if @timeline_entry.is_good
      politician.inc(:bad_link_count, 1) unless @timeline_entry.is_good
    end

    respond_to do |format|
      if @timeline_entry.save
        format.html { redirect_to @timeline_entry, notice: 'Timeline entry was successfully created.' }
        format.json { render json: @timeline_entry, status: :created, location: @timeline_entry }
      else
        format.html { render action: "new" }
        format.json { render json: @timeline_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /timeline_entries/1
  # PUT /timeline_entries/1.json
  def update
    @timeline_entry = TimelineEntry.find(params[:id])

    respond_to do |format|
      if @timeline_entry.update_attributes(params[:timeline_entry])
        format.html { redirect_to @timeline_entry, notice: 'Timeline entry was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @timeline_entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /timeline_entries/1
  # DELETE /timeline_entries/1.json
  def destroy
    @timeline_entry = TimelineEntry.find(params[:id],:user_id => current_user.id)
    # rather than @timeline_entry.destroy, we mark deleted
    @timeline_entry.deleted = true
    @timeline_entry.save

    respond_to do |format|
      format.html { redirect_to timeline_entries_url }
      format.json { head :no_content }
    end
  end
end
