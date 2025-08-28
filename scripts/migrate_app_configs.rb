# Based on https://gist.github.com/daronco/315fc5674634f11aa9790741560bbe6e

# DRYRUN=1 JSON_FILE_PATH=tmp/consumer_configs.json ./bin/rails runner scripts/migrate_app_configs.rb

JSONFILE = ENV['JSON_FILE_PATH'] || Rails.root.join('tmp', 'consumer_configs.json')
OUTPUTFILE = 'tmp/output_migrate_app_configs.log'
DRYRUN = ENV['DRYRUN'] == '0' ? false : true

@logfile = nil

def puts2(str)
  @logfile.puts str
  puts str
end

def populate_tenant_inst_guids
  RailsLti2Provider::Tenant.find_each do |tenant|
    rooms_app_settings = tenant.settings['rooms'].presence || tenant.settings['tool'].presence
    worka_app_settings = tenant.settings['worka']

    # No tenant settings, try to get institution_guid from app_settings of tools associated with
    # the tenant
    if rooms_app_settings.blank? && worka_app_settings.blank?
      puts2 "XXX No settings found for tenant '#{tenant.uid}', trying its tools... "
      tenant.tools.each do |tool|
        rooms_app_settings = tool.app_settings['rooms'].presence || tool.app_settings['tool'].presence
        worka_app_settings = tool.app_settings['worka']
        next if rooms_app_settings.blank? && worka_app_settings.blank?

        if rooms_app_settings
          params = { institution_guid: rooms_app_settings['institution_guid'] }
          puts2 ">>> From app_settings['rooms'] of tool '#{tool.uuid}': \n" \
          "\t *** Updating institution_guid, params=#{params}"
          tenant.update(institution_guid: rooms_app_settings['institution_guid']) unless DRYRUN
          return
        elsif worka_app_settings && worka_app_settings.keys.include?('worka_self_hosted_institution_guid')
          params = { institution_guid: worka_app_settings['worka_self_hosted_institution_guid'] }
          puts2 ">>> From app_settings['worka'] of tool '#{tool.uuid}': \n" \
          "\t *** Updating institution_guid, params=#{params}"
          tenant.update(institution_guid: worka_app_settings['worka_self_hosted_institution_guid']) unless DRYRUN
          return
        end
      end
      puts2 'No settings found in any tool either, skipping...'

    # Get institution_guid from Tenant settings (either for Rooms or Worka)
    else
      if rooms_app_settings
        params = { institution_guid: rooms_app_settings['institution_guid'] }
        puts2 ">>> From settings['rooms'] of tenant '#{tenant.uid}': \n" \
        "\t *** Updating institution_guid, params=#{params}"
        tenant.update(institution_guid: rooms_app_settings['institution_guid']) unless DRYRUN
      elsif worka_app_settings && worka_app_settings.keys.include?('worka_self_hosted_institution_guid')
        params = { institution_guid: worka_app_settings['worka_self_hosted_institution_guid'] }
        puts2 ">>> From settings['worka'] of tenant '#{tenant.uid}': \n" \
        "\t *** Updating institution_guid, params=#{params}"
        tenant.update(institution_guid: worka_app_settings['worka_self_hosted_institution_guid']) unless DRYRUN
      end
    end
  end
end

def init_bbb_configs_from_app_settings
  RailsLti2Provider::Tenant.find_each do |tenant|
    worka_app_settings = tenant.settings['worka']
    if worka_app_settings.blank?
      puts2 "XXX No Worka app_settings found for tenant '#{tenant.uid}', skipping..."
      next
    end

    # If has any BBB settings for Worka app
    if worka_app_settings.keys.any? { |key| key.start_with?('worka_self_hosted_bbb_') }
      puts2 ">>> From settings['worka'] of tenant '#{tenant.uid}':"
      params = {
        url: worka_app_settings['worka_self_hosted_bbb_api_url'],
        secret: worka_app_settings['worka_self_hosted_bbb_api_secret']
      }
      # Update/create bbb_configs for all tools associated with the tenant
      tenant.tools.each do |tool|
        if tool.bbb_config
          puts2 "\t *** Updating bbb_config of tool '#{tool.uuid}', params=#{params}"
          tool.bbb_config.update(params) unless DRYRUN
        else
          puts2 "\t +++ Creating bbb_config for tool '#{tool.uuid}', params=#{params}"
          tool.create_bbb_config(params) unless DRYRUN
        end
      end
    end
  end

  RailsLti2Provider::Tool.find_each do |tool|
    worka_app_settings = tool.app_settings['worka']
    if worka_app_settings.blank?
      puts2 "XXX No Worka app_settings found for tool '#{tool.uuid}', skipping..."
      next
    end

    # If has any BBB settings for Worka app
    if worka_app_settings.keys.any? { |key| key.start_with?('worka_self_hosted_bbb_') }
      puts2 ">>> From app_settings['worka'] of tool '#{tool.uuid}':"
      params = {
        url: worka_app_settings['worka_self_hosted_bbb_api_url'],
        secret: worka_app_settings['worka_self_hosted_bbb_api_secret']
      }.compact
      # Update/create bbb_config for the tool
      if tool.bbb_config
        puts2 "\t *** Updating bbb_config, params=#{params}"
        tool.bbb_config.update(params) unless DRYRUN
      else
        puts2 "\t +++ Creating bbb_config, params=#{params}"
        tool.create_bbb_config(params) unless DRYRUN
      end
    else
      puts2 ">>> No BBB settings found in Worka app_settings for tool '#{tool.uuid}', skipping..."
    end
  end
end


def init_worka_app_configs_from_app_settings
  # Tenants
  RailsLti2Provider::Tenant.find_each do |tenant|
    worka_app_settings = tenant.settings['worka']
    if worka_app_settings.blank?
      puts2 "XXX No Worka app_settings found for tenant '#{tenant.uid}', skipping..."
      next
    end

    # If has any non-BBB settings for Worka app
    if worka_app_settings.reject { |key, _| key.start_with?('worka_self_hosted_bbb_') }.any?
      puts2 ">>> From settings['worka'] of tenant '#{tenant.uid}':"
      params = {
        self_hosted_url: worka_app_settings['worka_self_hosted_url'],
        self_hosted_map_url: worka_app_settings['worka_self_hosted_map_url'],
        saas_world_url: worka_app_settings['worka_saas_world_url'],
        saas_map_url: worka_app_settings['worka_saas_map_url'],
        saas_map_storage_url: worka_app_settings['worka_saas_map_storage_url']
      }
      # Update/create worka_app_configs for all tools associated with the tenant
      tenant.tools.each do |tool|
        if tool.worka_app_config
          puts2 "\t *** Updating worka_app_config of tool '#{tool.uuid}', params=#{params}"
          tool.worka_app_config.update(params) unless DRYRUN
        else
          puts2 "\t +++ Creating worka_app_config for tool '#{tool.uuid}', params=#{params}"
          tool.create_worka_app_config(params) unless DRYRUN
        end
      end
    end
  end

  # Tools
  RailsLti2Provider::Tool.find_each do |tool|
    worka_app_settings = tool.app_settings['worka']
    if worka_app_settings.blank?
      puts2 "XXX No Worka app_settings found for tool '#{tool.uuid}', skipping..."
      next
    end

    # If has any non-BBB settings for Worka app
    if worka_app_settings.reject { |key, _| key.start_with?('worka_self_hosted_bbb_') }.any?
      puts2 ">>> From app_settings['worka'] of tool '#{tool.uuid}':"
      params = {
        self_hosted_url: worka_app_settings['worka_self_hosted_url'],
        self_hosted_map_url: worka_app_settings['worka_self_hosted_map_url'],
        saas_enabled: !!worka_app_settings['worka_saas_enabled'],
        saas_world_url: worka_app_settings['worka_saas_world_url'],
        saas_map_url: worka_app_settings['worka_saas_map_url'],
        saas_map_storage_url: worka_app_settings['worka_saas_map_storage_url']
      }.compact
      # Update/create worka_app_config for the tool
      if tool.worka_app_config
        puts2 "\t *** Updating worka_app_config, params=#{params}"
        tool.worka_app_config.update(params) unless DRYRUN
      else
        puts2 "\t +++ Creating worka_app_config, params=#{params}"
        tool.create_worka_app_config(params) unless DRYRUN
      end
    end
  end
end

# parse JSON file containing ConsumerConfigs, ConsumerConfigServers,
# MoodleTokens and ConsumerConfigBrightspaceOauth from Rooms db
def init_rooms_app_configs_from_json_file
  unless File.exist?(JSONFILE)
    puts2 "File #{JSONFILE} not found"
    return
  end

  json_data = JSON.parse(File.read(JSONFILE))
  json_data.each do |consumer_config|
    tool = RailsLti2Provider::Tool.find_by(uuid: consumer_config['key'])
    unless tool
      puts2 "XXX Tool with uuid '#{consumer_config['key']}' not found, skipping..."
      next
    end

    puts2 ">>> Processing tool with uuid '#{tool.uuid}'"

    # RoomsAppConfig
    rooms_app_config_params = {
      set_duration: consumer_config['set_duration'],
      download_presentation_video: consumer_config['download_presentation_video'],
      message_reference_terms_use: consumer_config['message_reference_terms_use'],
      force_disable_external_link: consumer_config['force_disable_external_link'],
      external_disclaimer: consumer_config['external_disclaimer'],
      external_widget: consumer_config['external_widget'],
      external_context_url: consumer_config['external_context_url']
    }
    if tool.rooms_app_config
      puts2 "\t *** Updating rooms_app_config, params=#{rooms_app_config_params}"
      tool.rooms_app_config.update(rooms_app_config_params) unless DRYRUN
    else
      puts2 "\t +++ Creating rooms_app_config, params=#{rooms_app_config_params}"
      tool.create_rooms_app_config(rooms_app_config_params) unless DRYRUN
    end

    # BbbConfig
    if consumer_config['server']
      bbb_config_params = {
        url: consumer_config['server']['endpoint'],
        internal_url: consumer_config['server']['internal_endpoint'],
        secret: consumer_config['server']['secret']
      }
      if tool.bbb_config
        puts2 "\t *** Updating bbb_config, params=#{bbb_config_params}"
        tool.bbb_config.update(bbb_config_params) unless DRYRUN
      else
        puts2 "\t +++ Creating bbb_config, params=#{bbb_config_params}"
        tool.create_bbb_config(bbb_config_params) unless DRYRUN
      end
    end

    # Moodle attributes
    if consumer_config['moodle_token']
      moodle_params = {
        moodle_integration_enabled: true,
        moodle_url: consumer_config['moodle_token']['url'],
        moodle_token: consumer_config['moodle_token']['token'],
        moodle_group_select_enabled: consumer_config['moodle_token']['group_select_enabled'],
        moodle_show_all_groups: consumer_config['moodle_token']['show_all_groups']
      }
      if tool.rooms_app_config
        puts2 "\t *** Updating Moodle attrs of rooms_app_config, params=#{moodle_params}"
        tool.rooms_app_config.update(moodle_params) unless DRYRUN
      else
        puts2 "\t +++ Creating rooms_app_config with Moodle attrs, params=#{moodle_params}"
        tool.create_rooms_app_config(moodle_params) unless DRYRUN
      end
    end

    # Brightspace attributes
    if consumer_config['brightspace_oauth']
      brightspace_params = {
        brightspace_integration_enabled: true,
        brightspace_oauth_url: consumer_config['brightspace_oauth']['url'],
        brightspace_oauth_client_id: consumer_config['brightspace_oauth']['client_id'],
        brightspace_oauth_client_secret: consumer_config['brightspace_oauth']['client_secret'],
        brightspace_oauth_scopes: consumer_config['brightspace_oauth']['scope']
      }
      if tool.rooms_app_config
        puts2 "\t *** Updating Brightspace attrs of rooms_app_config, params=#{brightspace_params}"
        tool.rooms_app_config.update(brightspace_params) unless DRYRUN
      else
        puts2 "\t +++ Creating rooms_app_config with Brightspace attrs, params=#{brightspace_params}"
        tool.create_rooms_app_config(brightspace_params) unless DRYRUN
      end
    end
    puts2 '<<<'
  end
rescue StandardError => e
  puts2 "!!! Error processing JSON file: #{e}"
end

def run
  global_start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts2 "Starting #{__FILE__} in #{DRYRUN ? 'DRYRUN' : 'REAL'} mode..."

  puts2 "\n###### Setting institution_guids in tenants"
  populate_tenant_inst_guids
  puts2 '######'; puts2 ''

  puts2 '###### Populating bbb_configs from Worka app_settings'
  init_bbb_configs_from_app_settings
  puts2 '######'; puts2 ''

  puts2 '###### Populating worka_app_configs from Worka app_settings'
  init_worka_app_configs_from_app_settings
  puts2 '######'; puts2 ''

  puts2 '###### Populating rooms_app_configs from JSON file'
  init_rooms_app_configs_from_json_file
  puts2 '######'; puts2 ''

  puts2 "Done. Time elapsed: #{(Process.clock_gettime(Process::CLOCK_MONOTONIC) - global_start_time).round(3)}s"
end

File.open(OUTPUTFILE, 'w') do |output_file|
  @logfile = output_file
  run
end
