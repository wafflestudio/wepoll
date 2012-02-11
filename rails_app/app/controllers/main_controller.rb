class MainController < ApplicationController
  def index
    @politicians = Politician.all
  end


  def forum
    @politician = Politician.find(params[:politician_id])
  end

end
