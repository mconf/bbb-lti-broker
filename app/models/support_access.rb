# frozen_string_literal: true

# Who used the dash's support actions. The dash login is shared, so the operator typed in the
# form is the only record of the person behind each access.
class SupportAccess < ApplicationRecord
  belongs_to :tool, class_name: 'RailsLti2Provider::Tool', optional: true

  validates :operator, :kind, presence: true
end
