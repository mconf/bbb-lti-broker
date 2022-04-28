module Clients::Coc
  module Api
    class Request
      def initialize
        @access_token = ''

        @token_path = '/giul/api/oauth2/token/'
        @basic_details_path = '/giul/integration/v1/user/basic-details/'
        @byclassroom_path = '/giul/integration/v1/user/byclassroom'
        @school_structures_path = lambda do |school_id|
          "/giul/integration/v1/school/#{school_id}/structures"
        end
        @year = Time.zone.today.year
      end

      def fetch_access_token(code)
        query = { grant_type: 'authorization_code', code: code }
        req = build_basic_request(@token_path, query)
        result = send_event(req)

        return unless result

        @access_token = result['access_token']
      end

      def fetch_user_data
        req = build_request(@basic_details_path, { year: @year })
        raw_user_data = send_event(req)

        return [] unless raw_user_data

        schools_data = fetch_school_data
        schools_data.each do |school_data|
          school_data.extract_data_from(raw_user_data['escolas'])
        end

        Data::UserData.new(raw_user_data, schools_data)
      end

      def fetch_school_data
        school_and_classes_ids = fetch_school_and_classes_ids

        extract_schools_data(school_and_classes_ids)
      end

      def fetch_school_and_classes_ids
        query = { period: @year }
        req = build_request(@byclassroom_path, query)

        result = send_event(req)

        return [] unless result

        result['classificacoes']
      end

      def extract_schools_data(school_and_classes_id)
        query = { period: @year,
                  packageId: Rails.application.config.coc_package_id,
                  untilTo: 'TURMA', }

        school_and_classes_id.map do |class_data|
          school_id = class_data['escola_id']
          classes_ids = class_data['turmas']

          req = build_request(@school_structures_path.call(school_id), query)

          structures = send_event(req)

          school_data = Api::Data::SchoolData.new(school_id)
          school_data.parse_structures(structures, classes_ids)
          # If we don't find any class from class_data in the structure, return nil
          school_data unless school_data.segments.empty?
        end.compact
      end

      private

      def build_basic_request(path, query = {})
        headers = build_headers(:basic)
        url = build_url(path, query)

        [url, headers]
      end

      def build_request(path, query = {})
        headers = build_headers(:bearer)
        url = build_url(path, query)

        [url, headers]
      end

      def build_url(path, query = {})
        URI::HTTPS.build(
          scheme: 'https',
          host: Rails.application.config.coc_passaporte_host,
          path: path,
          query: URI.encode_www_form(query)
        ).to_s
      end

      def build_headers(type)
        case type
        when :basic
          client_id = Rails.application.config.coc_client_id
          client_secret = Rails.application.config.coc_client_secret
          { Authorization: "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}" }
        when :bearer
          { Authorization: "Bearer #{@access_token}", content_type: :json, accept: :json }
        end
      end

      def send_event(event)
        response = RestClient.get(*event)

        begin
          JSON.parse(response)
        rescue JSON::ParserError => e
          msg = "Failed to parse passaporte response: #{event}. "\
                "Message: #{e.message}"
          Rails.logger.error(msg)
          nil
        end
      end
    end
  end
end
