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

require 'test_helper'
require 'nokogiri'

class ToolProfileControllerTest < ActionDispatch::IntegrationTest
  # developer_mode_enabled is read from the environment once, at boot, so a test
  # cannot change it by setting ENV. Flip the resolved config instead.
  def with_developer_mode
    previous = Rails.configuration.developer_mode_enabled
    Rails.configuration.developer_mode_enabled = true
    yield
  ensure
    Rails.configuration.developer_mode_enabled = previous
  end

  test 'responds with xml_config for default with no parameters when developer mode is true' do
    with_developer_mode do
      get xml_config_path('default')
    end

    # Response must be successful
    assert_response(:success)

    # Element blti:title should never be empty
    doc = Nokogiri::XML(response.body)
    assert_not(doc.xpath('//blti:title').text.empty?)
  end

  test 'XML builder gives xml properties that are selected for cartridge link' do
    with_developer_mode do
      get "#{xml_config_path('default')}?selection_height=500&selection_width=500"
    end

    assert_response(:success)

    # Query parameters become <lticm:property> entries under <blti:extensions>.
    doc = Nokogiri::XML(response.body)
    properties = doc.xpath('//blti:extensions/lticm:property')
    assert_equal(['selection_height', 'selection_width'], properties.map { |p| p['name'] }.sort)
  end
end
