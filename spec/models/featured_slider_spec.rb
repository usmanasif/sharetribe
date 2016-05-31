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

require 'rails_helper'

RSpec.describe FeaturedSlider, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
