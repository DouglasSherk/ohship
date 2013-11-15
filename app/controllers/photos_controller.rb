class PhotosController < ApplicationController
  load_and_authorize_resource

  def show
    filename = @photo.file_name
    begin
      File.open(filename, 'rb') do |file|
        send_data file.read,
          :filename => File.basename(filename),
          :type => Mime::Type.lookup_by_extension(@photo.file_type.downcase) || 'application/octet-stream',
          :disposition => 'inline'

        Analytics.track(
          user_id: distinct_id,
          event: 'Package View Photo',
          properties: {
            'Id' => @photo.id,
            'Photo Type' => @photo.photo_type,
            'File Type' => @photo.file_type,
            'Description' => @photo.description,
          },
        )
      end
    rescue
      # File can't be found / accessed
      head :internal_server_error
    end
  end
end
