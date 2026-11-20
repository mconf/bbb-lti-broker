# frozen_string_literal: true

# Who launched from the dash. The dash login is shared, so the operator typed in the
# form is the only record of the person behind each access.
class DashLaunchLog < ApplicationRecord
  belongs_to :tool, class_name: 'RailsLti2Provider::Tool', optional: true

  validates :operator, presence: true
end
