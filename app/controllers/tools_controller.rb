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

class ToolsController < ApplicationController
  skip_before_action :verify_authenticity_token

  http_basic_authenticate_with name: ENV['ADMIN_KEY'], password: ENV['ADMIN_PASSWORD']

  before_action :print_parameters if Rails.configuration.developer_mode_enabled
  before_action :find_tool, only: [:edit, :update, :destroy, :show]

  def show
  end

  def new
    @tool = RailsLti2Provider::Tool.new
    @tenants = RailsLti2Provider::Tenant.all.pluck(:uid, :id)
  end

  def edit
    @tenants = RailsLti2Provider::Tenant.all.pluck(:uid, :id)
  end

  def create
    tool = RailsLti2Provider::Tool.new(
      uuid: params[:uuid],
      shared_secret: params[:shared_secret],
      lti_version: 'LTI-1p0',
      tool_settings: 'none',
      tenant: RailsLti2Provider::Tenant.find_by(id: params[:tool][:tenant_id])
    )

    if tool.save
      redirect_to(registration_list_path)
    else
      redirect_to(new_tool_path)
    end
  end

  def update
    @tool.update!(
      uuid: params[:uuid],
      shared_secret: params[:shared_secret],
      tenant: RailsLti2Provider::Tenant.find_by(id: params[:tool][:tenant_id])
    )

    redirect_to(registration_list_path)
  end

  def destroy
    @tool.delete

    redirect_to(registration_list_path)
  end

  private

  def find_tool
    @tool = RailsLti2Provider::Tool.find_by(uuid: params['id'])
  end
end
