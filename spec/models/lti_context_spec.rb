# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(LtiContext) do
  include ActiveSupport::Testing::TimeHelpers

  describe '.rooms_handler' do
    JSON.parse(Rails.root.join('spec/fixtures/files/rooms_handler_vectors.json').read)['vectors'].each do |vector|
      it "matches Rooms: #{vector['name']}" do
        expect(described_class.rooms_handler(vector['message'])).to(eq(vector['handler']))
      end
    end
  end

  describe '.record_launch' do
    let(:tenant) { RailsLti2Provider::Tenant.create!(uid: 'context-spec') }
    let(:tool) { RailsLti2Provider::Tool.create!(uuid: 'context-spec', shared_secret: 'secret', lti_version: 'LTI-1p0', tenant: tenant, app_settings: {}) }
    let(:message) do
      {
        'context_id' => 'course-1', 'context_title' => 'Calculus I', 'resource_link_id' => 'link-1',
        'resource_link_title' => 'Class room', 'lti_version' => 'LTI-1p0', 'tool_consumer_instance_guid' => 'lms.example.com',
        'user_id' => 'user-1', 'lis_person_contact_email_primary' => 'jane@example.com',
        'custom_params' => { 'oauth_consumer_key' => 'context-spec', 'bbb' => { 'secret' => 'bbb-secret' } },
      }
    end

    it 'stores where a Rooms launch landed, without user data or custom params' do
      described_class.record_launch(tool, 'rooms', message)

      context = described_class.sole
      expect(context).to(have_attributes(
                           tool: tool, app: 'rooms', rooms_handler: Digest::SHA1.hexdigest('roomscontext-speccourse-1'),
                           oauth_consumer_key: 'context-spec', context_id: 'course-1', context_title: 'Calculus I',
                           resource_link_id: 'link-1', lti_version: 'LTI-1p0', groups_scoping: false
                         ))
      expect(context.attributes.values.join).not_to(include('user-1', 'jane@example.com', 'bbb-secret'))
    end

    it 'keeps one row per resource link, refreshed by the latest launch' do
      described_class.record_launch(tool, 'rooms', message)
      described_class.record_launch(tool, 'rooms', message.merge('resource_link_id' => 'link-2'))
      travel(1.hour) do
        described_class.record_launch(tool, 'rooms', message.merge('context_title' => 'Calculus I - 2026'))
      end

      expect(described_class.count).to(eq(2))
      expect(described_class.find_by(resource_link_id: 'link-1'))
        .to(have_attributes(context_title: 'Calculus I - 2026', last_launch_at: be_within(1.minute).of(1.hour.from_now)))
    end

    it 'stores launches into other apps, with no Rooms room' do
      described_class.record_launch(tool, 'worka', message)
      expect(described_class.sole).to(have_attributes(app: 'worka', context_id: 'course-1', rooms_handler: nil))
    end

    it 'keeps a single row for launches without a course or resource link' do
      2.times { described_class.record_launch(tool, 'rooms', message.except('context_id', 'resource_link_id')) }
      expect(described_class.sole).to(have_attributes(context_id: '', resource_link_id: '', rooms_handler: nil))
    end

    it 'skips launches the broker answers itself' do
      described_class.record_launch(tool, 'default', message)
      expect(described_class.count).to(eq(0))
    end
  end
end
