class HomeController < ApplicationController
  layout 'application'

  def index
    if current_user
      redirect_to '/packages'
    end
  end

  def how_it_works

  end
end
