# frozen_string_literal: true

# Shared setup for the dash, registration and LTI 1.3 launch specs
module LtiHelpers
  LEARNER = 'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'
  INSTRUCTOR = 'http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'

  def auth_headers
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials(ENV.fetch('ADMIN_KEY'), ENV.fetch('ADMIN_PASSWORD'))
    { 'HTTP_AUTHORIZATION' => credentials }
  end

  def create_key_pair(tool_id: nil)
    private_key = OpenSSL::PKey::RSA.generate(2048)
    RsaKeyPair.create!(private_key: private_key.to_s, public_key: private_key.public_key.to_s, tool_id: tool_id)
  end

  # The apps authenticate with a Doorkeeper client token; any token is accepted
  def stub_doorkeeper_token
    allow_any_instance_of(Api::V1::SessionsController).to(receive(:doorkeeper_token).and_return(instance_double(Doorkeeper::AccessToken, acceptable?: true)))
  end

  # User and course claims of an LTI 1.3 launch, without the ones that identify the platform and the request
  def lti13_claims(roles: [LEARNER])
    {
      'sub' => 'user-1',
      'name' => 'Jane Doe',
      'given_name' => 'Jane',
      'family_name' => 'Doe',
      'email' => 'jane@example.com',
      'https://purl.imsglobal.org/spec/lti/claim/message_type' => 'LtiResourceLinkRequest',
      'https://purl.imsglobal.org/spec/lti/claim/version' => '1.3.0',
      'https://purl.imsglobal.org/spec/lti/claim/roles' => roles,
      'https://purl.imsglobal.org/spec/lti/claim/context' => { 'id' => 'course-1', 'label' => 'CALC1', 'title' => 'Calculus I' },
      'https://purl.imsglobal.org/spec/lti/claim/resource_link' => { 'id' => 'link-1', 'title' => 'Class room' },
      'https://purl.imsglobal.org/spec/lti/claim/tool_platform' => { 'guid' => 'platform-guid', 'url' => 'https://lms.example.com' },
      'https://purl.imsglobal.org/spec/lti/claim/launch_presentation' => { 'locale' => 'pt_br' },
    }
  end
end

RSpec.configure do |config|
  config.include(LtiHelpers)
end
