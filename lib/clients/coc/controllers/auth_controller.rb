# frozen_string_literal: true

module Clients::Coc
  module Controllers
    class AuthController < ApplicationController
      def callback
        @code = params[:code]
        render 'loader/index'
      end

      def launch
        @api_request = Api::Request.new
        @api_request.fetch_access_token(params[:code])
        user_data = @api_request.fetch_user_data

        @current_user = find_or_create_user(user_data)

        app_launch = find_or_create_app_launch(user_data)

        redirector = "#{coc_app_launch_url('coc')}?#{{ launch_nonce: app_launch.nonce }.to_query}"
        redirect_to(redirector)
      end

      private

      def find_or_create_user(user_data)
        context = user_data.economic_group[:name]
        user_id = user_data.id

        user = User.find_or_create_by(context: context, uid: user_id) do |u|
          u.update(user_params(context, adapted_user_params(user_data)))
        end
        user.update(last_accessed_at: Time.current)
        user
      end

      def coc_app_launch_url(name)
        app = Doorkeeper::Application.where(name: name).first
        uri = URI.parse(app.redirect_uri)
        path = uri.path.split('/')
        path.delete_at(0)
        path = path.first(path.size - 3)
        URI.join(uri, "/#{path.join('/')}/coc/launch.html").to_s
      end

      # FIX ME no first and last name (we need it?)
      def adapted_user_params(user_data)
        {
          'user_id' => user_data.id,
          'lis_person_name_full' => user_data.name,
          'lis_person_name_given' => '',
          'lis_person_name_family' => '',
        }
      end

      def find_or_create_app_launch(user_data)
        tool = RailsLti2Provider::Tool.where(uuid: Rails.application.config.coc_consumer_key).last

        # FIX ME MAYBE
        nonce = 'coc-' + SecureRandom.hex

        # add the oauth key to the data of this launch

        message = build_message(user_data)
        AppLaunch.find_or_create_by(nonce: nonce) do |launch|
          launch.update(tool_id: tool.id, message: message.to_json)
        end
      end

      def build_message(user_data)
        message =
          {
            'context_id' => user_data.economic_group[:id],
            'tool_consumer_instance_guid' => user_data.economic_group[:name],
            'custom_params' => {
              'oauth_consumer_key' => Rails.application.config.coc_consumer_key,
              'schools' => user_data.schools,
            },
            'roles' => user_data.roles,
            'lis_outcome_service_url' => 'https://' + Rails.application.config.coc_portal_host
          }
        message.merge!(adapted_user_params(user_data))
      end
    end
  end
end
