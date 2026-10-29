# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(ApplicationController, type: :controller) do
  describe '#on500' do
    # The test env keeps consider_all_requests_local on, so ApplicationController skips its
    # rescue_from handlers. Register the 500 one here to exercise on500 as it runs in production.
    controller do
      rescue_from StandardError, with: :on500

      def index
        raise('boom from the spec')
      end
    end

    it 'logs the exception and its backtrace' do
      allow(controller.logger).to(receive(:error))
      get :index
      expect(response).to(have_http_status(:internal_server_error))
      expect(controller.logger).to(have_received(:error).with('RuntimeError: boom from the spec'))
      expect(controller.logger).to(have_received(:error).with(a_string_including('application_controller_spec.rb')))
    end
  end
end
