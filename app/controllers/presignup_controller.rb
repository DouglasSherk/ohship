class PresignupController < ApplicationController
  respond_to :json

  def index
    @presignup = Presignup.new
    @presignup[:email] = params[:q]
    if @presignup.save
      render json: '', status: :created
    else
      render json: '', status: :unprocessable_entity
    end
  end
end
