class HomeController < ApplicationController
  layout 'application'

  def index
    if current_user
      redirect_to '/packages'
    end
  end

  def details
  end

  def terms
  end

  def prohibited
  end
end
