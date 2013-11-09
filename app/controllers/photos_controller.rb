class PhotosController < ApplicationController
  load_and_authorize_resource

  def show
    filename = @photo.id.to_s + '.' + @photo.file_type
    File.open(Rails.root.join('uploads', filename), 'rb') do |file|
      send_data file.read,
        :filename => filename,
        :type => Mime::Type.lookup_by_extension(@photo.file_type.downcase) || 'application/octet-stream',
        :disposition => 'inline'

      Analytics.track(
        user_id: current_user.id,
        event: 'Package View Photo',
        properties: {
          'Id' => @photo.id,
          'Photo Type' => @photo.photo_type,
          'File Type' => @photo.file_type,
          'Description' => @photo.description,
        },
      )
    end
  end
end
