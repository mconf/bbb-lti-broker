# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

class RsaKeyPair < ApplicationRecord
  SERIALIZATION_HIDDEN = %w[private_key].freeze

  # Keep the private key out of to_json/to_xml, even when the caller asks for it: the dash
  # exports take :only and :methods straight from the request params
  def serializable_hash(options = nil)
    options = options.to_h
    super(options.merge(
      only: options[:only] && (Array(options[:only]).map(&:to_s) - SERIALIZATION_HIDDEN),
      except: Array(options[:except]).map(&:to_s) | SERIALIZATION_HIDDEN,
      methods: options[:methods] && (Array(options[:methods]).map(&:to_s) - SERIALIZATION_HIDDEN)
    ).compact)
  end

  def tool
    RailsLti2Provider::Tool.find_by_uuid(self.tool_id)
  end
end
