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

class TenantsController < ApplicationController
  skip_before_action :verify_authenticity_token

  http_basic_authenticate_with name: Mconf::Env.fetch('ADMIN_KEY'), password: Mconf::Env.fetch('ADMIN_PASSWORD')

  before_action :print_parameters if Rails.configuration.developer_mode_enabled
  before_action :find_tenant, only: [:edit, :update, :destroy]

  def new
  end

  def edit
  end

  def create
    tenant = RailsLti2Provider::Tenant.new(tenant_params)
    if tenant.save
      redirect_to(registration_list_path)
    else
      redirect_to(new_tenant_path)
    end
  end

  def update
    if @tenant.update(tenant_params)
      redirect_to(registration_list_path)
    else
      redirect_to(edit_tenant_path(@tenant.uid))
    end
  end

  def destroy
    @tenant.destroy

    redirect_to(registration_list_path)
  end

  private

  def find_tenant
    @tenant = RailsLti2Provider::Tenant.find_by(uid: params['id'])
  end

  def tenant_params
    params.require(:tenant).permit(:uid, settings: {}).tap do |whitelisted|
      # Reject blank values inside inner hashes
      whitelisted[:settings].each do |key, value|
        whitelisted[:settings][key].reject! { |_, value| value.blank? }
      end
    end
  end
end
