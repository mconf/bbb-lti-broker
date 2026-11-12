# frozen_string_literal: true

require 'rails_helper'

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
