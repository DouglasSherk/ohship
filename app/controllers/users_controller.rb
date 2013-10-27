class UsersController < ApplicationController
  def profile
    @signup = params[:signup]
  end
end
