# == Schema Information
#
# Table name: featured_sliders
#
#  id         :integer          not null, primary key
#  listing_id :integer
#  is_active  :boolean
#  image_for  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class FeaturedSlider < ActiveRecord::Base
	belongs_to :listing

  def image_status
    self.image_for
  end
end
