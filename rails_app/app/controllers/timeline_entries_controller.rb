class TimelineEntriesController < ApplicationController
  # GET /timeline_entries
  # GET /timeline_entries.json
  def index
  	if params[:from]
	    @timeline_entries = TimelineEntry.where(:updated_at => {'$gte' => params[:from]})
	  else
	    @timeline_entries = TimelineEntry.all
	  end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @timeline_entries }
    end
  end

  # GET /timeline_entries/1
  # GET /timeline_entries/1.json
  def show
    @timeline_entry = TimelineEntry.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @timeline_entry }
    end
  end

  # GET /timeline_entries/new
  # GET /timeline_entries/new.json
  def new
    @timeline_entry = TimelineEntry.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @timeline_entry }
    end
  end

  # GET /timeline_entries/1/edit
  def edit
    @timeline_entry = TimelineEntry.find(params[:id])
  end

  # POST /timeline_entries
  # POST /timeline_entries.json
  def create
    @timeline_entry = TimelineEntry.new(params[:timeline_entry])

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
    @timeline_entry = TimelineEntry.find(params[:id])
    @timeline_entry.destroy

    respond_to do |format|
      format.html { redirect_to timeline_entries_url }
      format.json { head :no_content }
    end
  end
end