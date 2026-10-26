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
