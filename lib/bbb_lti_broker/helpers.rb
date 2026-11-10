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

module BbbLtiBroker
  module Helpers
    def string_to_hash(str)
      Hash[
        str.split(',').map do |pair|
          k, v = pair.split(':', 2)
          [k, v]
        end
      ]
    end

    def log_div(seed, num)
      div = seed
      (1..num).each do |_i|
        div += seed
      end
      logger.info(div)
    end

    def log_hash(hash, msg = nil)
      logger.debug(msg) if msg
      log_div('*', 100)
      hash.sort.map do |key, value|
        logger.debug("#{key}: " + value)
      end
      log_div('*', 100)
    end

    def secure_url(url)
      return nil if url.nil?
      uri = URI.parse(url)
      uri.scheme = 'https'
      uri.to_s
    end

    ##
    # Standardize a message to be sent to the registered app for backward compatibility with LTI 1.0.
    #
    # When the message comes from an LTI 1.3 launch, the claims are extracted and placed at the root level
    # with the naming and format LTI 1.0 used to have. Launches stored before MessageController started adding
    # the custom params to the message wrap the claims in 'unknown_params'; newer ones keep them at the root.
    #
    def standarized_message(message_json)
      message = JSON.parse(message_json)
      if message['user_id'].blank?
        claims = message['unknown_params'] || message
        migration_map.each do |param, claim|
          name, field = claim.split('#')
          value = claims[name]
          value = value.is_a?(Hash) ? value[field] : nil if field
          value = value.join(',') if value.is_a?(Array)
          message[param.to_s] = value unless value.nil?
        end
      end
      custom_overrides(message).to_json
    end

    def user_params(tc_instance_guid, params)
      if params['user_id'].blank?
        params['user_id'] = params['sub']
        params['lis_person_name_full'] = params['name']
        params['lis_person_name_given'] = params['given_name']
        params['lis_person_name_family'] = params['family_name']
      end
      {
        context: tc_instance_guid,
        uid: params['user_id'],
        full_name: params['lis_person_name_full'],
        first_name: params['lis_person_name_given'],
        last_name: params['lis_person_name_family'],
        last_accessed_at: Time.current,
      }
    end

    # LTI 1.1 parameter => LTI 1.3 claim, with '#' separating the claim from its field
    def migration_map
      {
        lti_message_type: 'https://purl.imsglobal.org/spec/lti/claim/message_type',
        lti_version: 'https://purl.imsglobal.org/spec/lti/claim/version',
        user_id: 'sub',
        lis_person_name_given: 'given_name',
        lis_person_name_family: 'family_name',
        lis_person_name_full: 'name',
        lis_person_contact_email_primary: 'email',
        user_image: 'picture',
        lis_person_sourcedid: 'https://purl.imsglobal.org/spec/lti/claim/lis#person_sourcedid',
        lis_course_offering_sourcedid: 'https://purl.imsglobal.org/spec/lti/claim/lis#course_offering_sourcedid',
        lis_course_section_sourcedid: 'https://purl.imsglobal.org/spec/lti/claim/lis#course_section_sourcedid',
        resource_link_id: 'https://purl.imsglobal.org/spec/lti/claim/resource_link#id',
        resource_link_title: 'https://purl.imsglobal.org/spec/lti/claim/resource_link#title',
        resource_link_description: 'https://purl.imsglobal.org/spec/lti/claim/resource_link#description',
        roles: 'https://purl.imsglobal.org/spec/lti/claim/roles',
        # The Rooms app needs context_id to calculate the room handler
        context_id: 'https://purl.imsglobal.org/spec/lti/claim/context#id',
        context_type: 'https://purl.imsglobal.org/spec/lti/claim/context#type',
        context_title: 'https://purl.imsglobal.org/spec/lti/claim/context#title',
        context_label: 'https://purl.imsglobal.org/spec/lti/claim/context#label',
        launch_presentation_locale: 'https://purl.imsglobal.org/spec/lti/claim/launch_presentation#locale',
        launch_presentation_document_target: 'https://purl.imsglobal.org/spec/lti/claim/launch_presentation#document_target',
        launch_presentation_width: 'https://purl.imsglobal.org/spec/lti/claim/launch_presentation#width',
        launch_presentation_height: 'https://purl.imsglobal.org/spec/lti/claim/launch_presentation#height',
        launch_presentation_return_url: 'https://purl.imsglobal.org/spec/lti/claim/launch_presentation#return_url',
        tool_consumer_info_product_family: 'https://purl.imsglobal.org/spec/lti/claim/tool_platform#product_family_code',
        tool_consumer_info_version: 'https://purl.imsglobal.org/spec/lti/claim/tool_platform#version',
        tool_consumer_instance_guid: 'https://purl.imsglobal.org/spec/lti/claim/tool_platform#guid',
        tool_consumer_instance_name: 'https://purl.imsglobal.org/spec/lti/claim/tool_platform#name',
        tool_consumer_instance_description: 'https://purl.imsglobal.org/spec/lti/claim/tool_platform#description',
        tool_consumer_instance_url: 'https://purl.imsglobal.org/spec/lti/claim/tool_platform#url',
        tool_consumer_instance_contact_email: 'https://purl.imsglobal.org/spec/lti/claim/tool_platform#email',
        custom_keyname: 'https://purl.imsglobal.org/spec/lti/claim/custom#keyname',
        role_scope_mentor: 'https://purl.imsglobal.org/spec/lti/claim/role_scope_mentor',
      }
    end

    ##
    # Overrides core parameters with custom parameters when following certain pattern.
    #
    # Core parameters may have to be overriden in order to make the applications behave differently
    # for that, the LTI link in the tool consumer would need to include a custom parameter in the form:
    #
    # custom_resource_link_id=static:"some value" -> resource_link_id="some value"
    # custom_resource_link_id=param:contenxt_id   -> resource_link_id=<value obtained from context_id>
    # custom_resource_link_id="another value"     -> resource_link_id=<no overriding is made>
    #
    def custom_overrides(message)
      custom_params = message['custom_params'].to_h
      custom_params.select{ |key, _| key.start_with?('custom_') }.each do |key, value|
        custom_param = key.delete_prefix('custom_')
        pattern = value.split(':')
        message[custom_param] = pattern[1] if pattern[0] == 'static'
        message[custom_param] = message[pattern[1]] if pattern[0] == 'param'
      end
      message
    end
  end
end
