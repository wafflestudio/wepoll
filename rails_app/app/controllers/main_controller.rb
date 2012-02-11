class MainController < ApplicationController
  def index
    @politicians = Politician.all.limit(10)
  end


  def forum
    @politician = Politician.find(params[:politician_id])
  end

end
