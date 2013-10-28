class Photo < ActiveRecord::Base
  before_destroy :delete_file
  belongs_to :package

  def file_name
    Rails.root.join('uploads', self.id.to_s + '.' + self.file_type)
  end

  private
    def delete_file
      File.delete(file_name) rescue nil
    end
end
