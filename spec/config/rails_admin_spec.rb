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

RSpec.describe('RailsAdmin EduplayAppConfig config') do
  def form_value(field_name, object)
    RailsAdmin.config(EduplayAppConfig).create.fields.find { |field| field.name == field_name }.with(object: object).form_value
  end

  around do |example|
    env = { 'EDUPLAY_DEFAULT_CLIENT_ID' => 'default-id', 'EDUPLAY_DEFAULT_CLIENT_KEY' => 'default-key', 'EDUPLAY_DEFAULT_URL' => 'https://eduplay.example' }
    original = ENV.to_h.slice(*env.keys)
    ENV.update(env)
    example.run
  ensure
    env.each_key { |key| original.key?(key) ? ENV[key] = original[key] : ENV.delete(key) }
  end

  it 'fills the client id, key and Eduplay url of a new config from the env' do
    expect(form_value(:client_id, EduplayAppConfig.new)).to(eq('default-id'))
    expect(form_value(:client_key, EduplayAppConfig.new)).to(eq('default-key'))
    expect(form_value(:eduplay_url, EduplayAppConfig.new)).to(eq('https://eduplay.example'))
  end

  it 'keeps the client id, key and Eduplay url of an existing config' do
    config = EduplayAppConfig.new(client_id: 'own-id', client_key: 'own-key', eduplay_url: 'https://own.example')
    allow(config).to(receive(:new_record?).and_return(false))
    expect(form_value(:client_id, config)).to(eq('own-id'))
    expect(form_value(:client_key, config)).to(eq('own-key'))
    expect(form_value(:eduplay_url, config)).to(eq('https://own.example'))
  end
end

RSpec.describe('RailsAdmin EduplayAppConfig form help') do
  def help_by_field
    RailsAdmin.config(EduplayAppConfig).edit.with(object: EduplayAppConfig.new).visible_fields.to_h { |field| [field.name, field.help] }
  end

  # RailsAdmin's generic "Optional. Length up to 255." hint is noise in this form
  it 'shows no generic optional hint' do
    expect(help_by_field.values).to(all(satisfy { |help| !help.to_s.start_with?('Optional') }))
  end

  it 'keeps the help written for specific fields' do
    expect(help_by_field[:enforce_private_student_submissions]).to(start_with('If enabled'))
    expect(help_by_field[:moodle_integration_enabled]).to(start_with('If disabled'))
  end
end
