class Feedback < ActiveRecord::Base
  self.table_name = 'feedback'
  belongs_to :package
end
