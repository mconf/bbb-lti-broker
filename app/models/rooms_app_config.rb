class RoomsAppConfig < ApplicationRecord
  belongs_to :tool, class_name: 'RailsLti2Provider::Tool'
end
