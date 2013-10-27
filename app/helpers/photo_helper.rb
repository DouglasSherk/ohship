module PhotoHelper
  def photo_path(photo)
    package_photo_path(photo.package, photo) + '.' + photo.file_type
  end
end
