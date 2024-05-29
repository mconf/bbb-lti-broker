# frozen_string_literal: true

namespace :db do
  namespace :registration do
    desc 'Add new Tool configuration [key, jwk]'
    task :new, [:type] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      abort('Type must be one of [key, jwk]') unless %w[key jwk].include?(args[:type])

      $stdout.puts('What is the issuer?')
      issuer = $stdin.gets.strip

      abort('The issuer must be valid.') if issuer.blank?

      $stdout.puts('What is the client id?')
      client_id = $stdin.gets.strip

      $stdout.puts('What is the key set url?')
      key_set_url = $stdin.gets.strip

      $stdout.puts('What is the access token url?')
      auth_token_url = $stdin.gets.strip

      $stdout.puts('What is the auth request url?')
      auth_login_url = $stdin.gets.strip

      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key
      jwk = JWT::JWK.new(private_key).export
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')
      jwk = jwk.to_json

      rsa_key_pair = RsaKeyPair.create(
        private_key: private_key.to_s,
        public_key: public_key.to_s,
        tool_id: client_id
      )

      reg = {
        issuer: issuer,
        client_id: client_id,
        key_set_url: key_set_url,
        auth_token_url: auth_token_url,
        auth_login_url: auth_login_url,
        rsa_key_pair_id: rsa_key_pair.id
      }

      RailsLti2Provider::Tool.create!(
        uuid: client_id,
        shared_secret: client_id,
        tool_settings: reg.to_json,
        lti_version: '1.3.0',
        tenant: RailsLti2Provider::Tenant.first
      )

      puts(jwk) if args[:type] == 'jwk'
      puts(public_key) if args[:type] == 'key'
    rescue StandardError => e
      puts(e.inspect)
      exit(1)
    end

    desc 'Add new Tool configuration (with all credentials passed as arguments)'
    task :create, [:issuer, :client_id, :key_set_url, :access_token_url, :auth_request_url, :tenant] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      issuer = args[:issuer]
      abort('The issuer must be valid.') if issuer.blank?

      client_id = args[:client_id]
      key_set_url = args[:key_set_url]
      auth_token_url = args[:access_token_url]
      auth_login_url = args[:auth_request_url]
      tenant = RailsLti2Provider::Tenant.find_by(uid: args[:tenant]) || RailsLti2Provider::Tenant.first

      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key
      jwk = JWT::JWK.new(private_key).export
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')
      jwk = jwk.to_json

      rsa_key_pair = RsaKeyPair.create(
        private_key: private_key.to_s,
        public_key: public_key.to_s,
        tool_id: client_id
      )

      reg = {
        issuer: issuer,
        client_id: client_id,
        key_set_url: key_set_url,
        auth_token_url: auth_token_url,
        auth_login_url: auth_login_url,
        rsa_key_pair_id: rsa_key_pair.id
      }

      RailsLti2Provider::Tool.create!(
        uuid: client_id,
        shared_secret: client_id,
        tool_settings: reg.to_json,
        lti_version: '1.3.0',
        tenant: tenant
      )

      puts(public_key)
    rescue StandardError => e
      puts(e.inspect)
      exit(1)
    end

    desc 'Delete existing Tool configuration'
    task :delete, [] => :environment do |_t, _args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection
      $stdout.puts('What is the issuer for the registration you wish to delete?')
      issuer = $stdin.gets.strip
      $stdout.puts('What is the client ID for the registration?')
      client_id = $stdin.gets.strip


      reg = RailsLti2Provider::Tool.find_by_uuid(client_id)

      if key_pair_id = JSON.parse(reg.tool_settings)['rsa_key_pair_id']
        RsaKeyPair.find(key_pair_id).destroy!
      end

      reg.destroy!
    end

    desc 'Generate new key pair for existing Tool configuration [key, jwk]'
    task :keygen, [:type] => :environment do |_t, args|
      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      abort('Type must be one of [key, jwk]') unless %w[key jwk].include?(args[:type])

      $stdout.puts('What is the issuer for the registration?')
      issuer = $stdin.gets.strip
      $stdout.puts('What is the client ID for the registration?')
      client_id = $stdin.gets.strip

      registration = RailsLti2Provider::Tool.find_by_issuer(client_id)

      abort('The registration must be valid.') if registration.blank?

      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key
      jwk = JWT::JWK.new(private_key).export
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')
      jwk = jwk.to_json

      tool_settings = JSON.parse(registration.tool_settings)
      key_pair = RsaKeyPair.find_by(id: tool_settings['rsa_key_pair_id'])
      if tool_settings['rsa_key_pair_id'].blank? || key_pair.nil?
        key_pair = RsaKeyPair.create(
          private_key: private_key.to_s,
          public_key: public_key.to_s,
          tool_id: client_id
        )
        tool_settings['rsa_key_pair_id'] = key_pair.id
        registration.update(tool_settings: tool_settings.to_json)
      else
        key_pair.update(
          private_key: private_key,
          public_key: public_key,
          tool_id: client_id
        )
      end

      puts(jwk) if args[:type] == 'jwk'
      puts(public_key) if args[:type] == 'key'
    end

    desc 'Lists the Registration Configuration URLs needed to register an app'
    task :url, [:app_name] => :environment do |_t, args|
      abort('An app name must be informed.') if args[:app_name].blank?

      include Rails.application.routes.url_helpers
      default_url_options[:host] = ENV['URL_HOST']

      Rake::Task['environment'].invoke
      ActiveRecord::Base.connection

      app = Doorkeeper::Application.find_by(name: args[:app_name])
      if app.nil?
        puts("App '#{args[:app_name]}' does not exist, no urls can be given.")
        exit(1)
      end

      # Setting temp keys
      private_key = OpenSSL::PKey::RSA.generate(4096)
      public_key = private_key.public_key

      jwk = JWT::JWK.new(private_key).export
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')
      jwk = jwk.to_json

      key_pair = RsaKeyPair.create(private_key: private_key.to_s, public_key: public_key.to_s)
      temp_key_token = SecureRandom.hex

      ActiveRecord::Base.connection.cache do
        Rails.cache.write(temp_key_token, rsa_key_pair_id: key_pair.id, timestamp: Time.now.to_i)
      end

      $stdout.puts("Tool URL: \n#{openid_launch_url(app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts("Deep Link URL: \n#{deep_link_request_launch_url(app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts("Initiate login URL: \n#{openid_login_url(app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts("Redirection URL(s):\n#{openid_launch_url(app: app.name)}\n#{deep_link_request_launch_url(app: app.name)}")
      $stdout.puts("\n")
      $stdout.puts("Public Key: \n#{public_key}")
      $stdout.puts("\n")
      $stdout.puts("JWK: \n#{jwk}")
      $stdout.puts("\n")
      $stdout.puts("JSON Configuration URL: \n#{json_config_url(app: app.name, temp_key_token: temp_key_token)}")
    end

    desc 'Deletes the RsaKeyPairs not associated with any tool'
    task :clear_rsa_keys, [] => :environment do |_t|
      RsaKeyPair.where(tool_id: nil).delete_all
    end
  end
end
