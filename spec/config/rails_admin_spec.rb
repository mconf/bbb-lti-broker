# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('RailsAdmin RsaKeyPair config') do
  # Support copies the public key from the dash; the private key must stay off every view
  %i[list show edit create export].each do |section|
    it "hides the private key in the #{section} section" do
      fields = RailsAdmin.config(RsaKeyPair).send(section).with({}).visible_fields.map(&:name)
      expect(fields).not_to(include(:private_key))
      expect(fields).to(include(:public_key))
    end
  end
end

RSpec.describe('RailsAdmin Tool config') do
  def lti_version_options(section)
    RailsAdmin.config(RailsLti2Provider::Tool).send(section).with(object: RailsLti2Provider::Tool.new).fields.find { |field| field.name == :lti_version }.enum
  end

  # The dash can't fill tool_settings, so a 1.3 Tool created there would be left with 'none'
  it 'leaves LTI 1.3 out of the versions offered on create' do
    expect(lti_version_options(:create)).to(eq(['LTI-1p0']))
  end

  # Without 1.3 in the options, saving an existing 1.3 Tool would turn it into 1.0
  it 'keeps LTI 1.3 among the versions offered on edit' do
    expect(lti_version_options(:edit)).to(eq(['LTI-1p0', '1.3.0']))
  end
end
