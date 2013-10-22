class PhotoController < ApplicationController
  before_action :set_photo, :only => [:show, :delete]

  def show
  end

  def create
  end

  def delete
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_photo
      @photo = Photo.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def photo_params
    end
end
