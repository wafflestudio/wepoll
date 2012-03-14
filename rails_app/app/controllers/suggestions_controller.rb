class SuggestionsController < ApplicationController
  layout :false

  # GET /suggestions/new
  # GET /suggestions/new.json
  def new
    @suggestion = Suggestion.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @suggestion }
    end
  end

  # POST /suggestions
  # POST /suggestions.json
  def create
    @suggestion = Suggestion.new(params[:suggestion])

    respond_to do |format|
      if @suggestion.save
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @suggestion.errors, status: :unprocessable_entity }
      end
    end
  end

end
