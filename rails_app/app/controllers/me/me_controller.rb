class Me::MeController < ApplicationController
  before_filter :authenticate_user!
end
