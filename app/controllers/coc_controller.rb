# frozen_string_literal: true

class CocController < ApplicationController
  def callback
    # mocked params[:app]
    params[:app] = 'rooms'

    access_token = fetch_access_token

    user_data = fetch_user_data(access_token)

    context = user_data[:economic_group][:name]
    user_id = user_data[:id]

    @current_user = User.find_or_create_by(context: context, uid: user_id) do |user|
      user.update(user_params(context, adapted_user_params(user_data)))
    end
    @current_user.update(last_accessed_at: Time.current)

    app_launch = create_app_launch(user_data)
    redirector = "#{coc_app_launch_url(params[:app])}?#{{ launch_nonce: app_launch.nonce }.to_query}"
    redirect_to(redirector)
  end

  def launch
    app_launch = create_app_launch
    redirector = "#{lti_app_url(params[:app])}?#{{ launch_nonce: app_launch.nonce }.to_query}"
    redirect_to(redirector)
  end

  def fetch_user_data(access_token)
    path = '/giul/integration/v1/user/basic-details/'
    req = build_request(access_token, path, { year: Time.zone.today.year })

    result = send_event(req)

    return [] unless result

    schools_data = fetch_school_data(access_token)

    user_data = {
      id: result['id'].to_s,
      name: result['nome'],
      email: result['login'],
      schools: combine_school_data(result['escolas'], schools_data),
      economic_group: {
        id: result['grupoEconomico']['id'].to_s,
        name: result['grupoEconomico']['nome'],
      },
    }

    user_data
  end

  def fetch_access_token
    code = params[:code]

    path = '/giul/api/oauth2/token/'
    query = { grant_type: 'authorization_code', code: code }
    req = build_basic_request(path, query)

    result = send_event(req)

    return unless result

    result['access_token']
  end

  def fetch_school_data(access_token)
    school_and_classes_ids = fetch_school_and_classes_ids(access_token)

    extract_schools_data(access_token, school_and_classes_ids)
  end

  def fetch_school_and_classes_ids(access_token)
    period = Time.zone.today.year

    path = '/giul/integration/v1/user/byclassroom'
    query = { period: period }
    req = build_request(access_token, path, query)

    result = send_event(req)

    return [] unless result

    result['classificacoes']
  end

  private

  # combine data that came from different APIs
  def combine_school_data(raw_schools, schools_data)
    raw_schools.map do |raw_school|
      school_data = schools_data.find do |s|
        s[:id] == raw_school['escola_id']
      end
      next unless school_data

      {
        id: raw_school['escola_id'],
        name: raw_school['escola_nome'],
        segments: school_data[:segments]
      }
    end.compact
  end

  def extract_schools_data(access_token, school_and_classes_id)
    query = { period: Time.zone.today.year,
              packageId: 'Portal_COC',
              untilTo: 'TURMA', }

    school_and_classes_id.map do |class_data|
      school_id = class_data['escola_id']

      path = "/giul/integration/v1/school/#{school_id}/structures"
      req = build_request(access_token, path, query)

      structures = send_event(req)

      school_data = {}
      structures.each do |segment|
        segment['series'].each do |grade|
          grade['turmas'].each do |klass|
            next unless klass['id'].in?(class_data['turmas'])

            school_data[:id] ||= school_id
            school_data[:segments] ||= []

            current_segment =
              school_data[:segments].find { |s| s[:id] == segment['id'] }
            # add current_segment if it's not in the school_data yet
            unless current_segment
              current_segment =
                { id: segment['id'], name: segment['nome'], grades: [] }
              school_data[:segments] << current_segment
            end

            current_grade =
              current_segment[:grades].find { |g| g[:id] == grade['id'] }
            # add current_grade if it's not in the school_data yet
            unless current_grade
              current_grade =
                { id: grade['id'], name: grade['nome'], classes: [] }
              current_segment[:grades] << current_grade
            end

            # add current_class
            current_grade[:classes] << { id: klass['id'], name: klass['nome'] }
          end
        end
      end
      school_data
    end
  end

  def coc_app_launch_url(name)
    # The launch target is always in the form [schema://hostname/app_prefix/launch]. Since the callback endpoint
    # registered for the app in Doorkeeper is as [schema://hostname/app_prefix/auth/bbbltibroker/callback],
    # it is safe to remove the last 2 segments from the path.
    app = Doorkeeper::Application.where(name: name).first
    uri = URI.parse(app.redirect_uri)
    path = uri.path.split('/')
    path.delete_at(0)
    path = path.first(path.size - 3)
    "#{URI.join(uri, '/')}#{path.join('/')}/coc/launch.html"
  end

  def adapted_user_params(user_data)
    {
      'user_id' => user_data[:id],
      'custom_lis_person_name_full' => user_data[:name],
      'custom_lis_person_name_given' => 'Professor',
      'custom_lis_person_name_family' => 'Portal',
    }
  end

  def create_app_launch(user_data)
    tool = RailsLti2Provider::Tool.where(uuid: 'my-coc-key').last

    # FIX ME MAYBE
    nonce = 'coc-' + SecureRandom.hex

    # add the oauth key to the data of this launch

    message = build_message(user_data)

    AppLaunch.find_or_create_by(nonce: nonce) do |launch|
      launch.update(tool_id: tool.id, message: message.to_json)
    end
  end

  def build_message(user_data)
    {
      'user_id' => user_data[:id],
      'context_id' => user_data[:id],
      'tool_consumer_instance_guid' => user_data[:economic_group][:name],
      'custom_params' => {
        'oauth_consumer_key' => 'my-coc-key',
        'schools' => user_data[:schools],
      },
    }
  end

  def build_basic_request(path, query = {})
    headers = build_headers(:basic)
    url = build_url(path, query)

    [url, headers]
  end

  def build_request(access_token, path, query = {})
    headers = build_headers(:bearer, { access_token: access_token })
    url = build_url(path, query)

    [url, headers]
  end

  def build_url(path, query = {})
    Rails.application.config.portal_coc_scheme = 'https'
    Rails.application.config.portal_coc_host = 'homolog-passaporte.pearsonbr.info'

    url = URI::HTTPS.build(
      scheme: Rails.application.config.portal_coc_scheme,
      host: Rails.application.config.portal_coc_host,
      path: path,
      query: URI.encode_www_form(query)
    ).to_s
  end

  def build_headers(type, args = {})
    case type
    when :basic
      client_id = Rails.application.config.coc_client_id
      client_secret = Rails.application.config.coc_client_secret
      { Authorization: "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}" }
    when :bearer
      { Authorization: "Bearer #{args[:access_token]}", content_type: :json, accept: :json }
    end
  end

  def send_event(event)
    response = RestClient.get(*event)

    begin
      JSON.parse(response)
    rescue JSON::ParserError => e
      msg = "Failed to parse passaporte response: #{event}. "\
            "Message: #{e.message}"
      puts(msg)
      nil
    end
  end
end
