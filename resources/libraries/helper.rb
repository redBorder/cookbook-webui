module Webui
  module Helper
    require 'openssl'
    require 'resolv'
    require 'base64'
    require 'securerandom'
    require 'aws-sdk-s3'
    require 'digest'

    def local_routes
      routes = []

      # Ejecuta el comando `ip route` y captura su salida
      ip_route_output = `ip route`
      ip_route_output.each_line do |line|
        next unless line.include?('link')

        # Obtiene el prefijo (por ejemplo, '192.168.1.0/24')
        prefix = line.split[0]
        routes.push(prefix) unless routes.include?(prefix)
      end
      routes
    end

    def create_cert(cn)
      # Return a hash with private key and certificate in x509 format
      key = OpenSSL::PKey::RSA.new 4096
      name = OpenSSL::X509::Name.parse "CN=#{cn}/DC=redborder"
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = SecureRandom.random_number(2**128)
      cert.not_before = Time.now
      cert.not_after = Time.now + (3600 * 24 * 365 * 10)
      cert.public_key = key.public_key
      cert.subject = name
      cert.issuer = name
      if cn.start_with?('s3.')
        extension_factory = OpenSSL::X509::ExtensionFactory.new nil, cert
        cert.add_extension extension_factory.create_extension('subjectAltName', "DNS:redborder.#{cn}", false)
        cert.add_extension extension_factory.create_extension('subjectAltName', "DNS:rbookshelf.#{cn}", false)
        cert.add_extension extension_factory.create_extension('subjectAltName', "DNS:#{cn}", false)
      end
      cert.sign key, OpenSSL::Digest.new('SHA512')
      { key: key, crt: cert }
    end

    def create_json_cert(app, cdomain)
      ret_json = { id: app }
      cert_hash = create_cert("#{app}.#{cdomain}")
      ret_json["#{app}_crt"] = Base64.urlsafe_encode64(cert_hash[:crt].to_pem)
      ret_json["#{app}_key"] = Base64.urlsafe_encode64(cert_hash[:key].to_pem)
      ret_json
    end

    # Normally you want to pass cdomain to this method but
    # you can avoid to pass it if you dont want to create the cert
    # when dont exists
    def nginx_certs(app, cdomain = nil)
      ret_json = {}
      # Check if certs exists in a data bag
      begin
        nginx_cert_item = data_bag_item('certs', app)
      rescue
        nginx_cert_item = {}
      end

      if nginx_cert_item.empty? && cdomain
        unless File.exist?("/var/chef/data/data_bag/certs/#{app}.json")
          # Create S3 certificate
          ret_json = create_json_cert(app, cdomain)
          system('mkdir -p /var/chef/data/data_bag/certs')
          File.write("/var/chef/data/data_bag/certs/#{app}.json", ret_json.to_json)
        end
        # Upload cert to data bag
        if File.exist?('/root/.chef/knife.rb')
          system("knife data bag from file certs /var/chef/data/data_bag/certs/#{app}.json")
        else
          Chef::Log.warn('knife command not available, certs databag wont be uploaded')
        end
      else
        ret_json = nginx_cert_item
      end
      ret_json
    end

    # Executes a Rake task with the specified parameters.
    #
    # @param task_name [String] The name of the Rake task to execute.
    # @param log_file  [String] The log file where the output of the Rake task will be appended.
    # @param home_path [String] The home directory path to set as the HOME environment variable.
    # @param env_vars  [Hash]   Optional. Environment variables to set before executing the Rake task.
    def execute_rake_task(task_name, log_file, home_path, env_vars = {})
      env_vars_string = env_vars.map { |k, v| "#{k}=#{v}" }.join(' ')
      env_prefix = env_vars_string.empty? ? '' : "env #{env_vars_string}"

      <<-EOH
        source /etc/profile.d/rvm.sh
        export HOME=#{home_path}
        pushd /var/www/rb-rails &>/dev/null
        echo "### `date` - COMMAND: #{env_prefix} bundle exec rake #{task_name}" &>>/var/www/rb-rails/log/#{log_file}
        rvm ruby-2.7.5@web do #{env_prefix} bundle exec rake #{task_name} &>>/var/www/rb-rails/log/#{log_file}
        popd &>/dev/null
      EOH
    end

    # Checks the synchronization status of files between a local directory and an S3 bucket.
    # @param bucket      [String] The name of the S3 bucket to check.
    # @param host        [String] The S3 endpoint URL.
    # @param access_key  [String] The AWS access key for authentication.
    # @param secret_key  [String] The AWS secret key for authentication.
    # @param local_path  [String] The local directory path to compare against the S3 bucket. Default is '/etc/redborder/http_agents'.
    # @param s3_prefix   [String] The prefix in the S3 bucket to check for files. Default is 'rb-webui/monitor_categories/'.
    def check_http_agent_s3_sync(bucket, host, access_key, secret_key, local_path = '/etc/redborder/http_agents', s3_prefix = 'rb-webui/monitor_categories/')
      client = Aws::S3::Client.new(
        region: 'us-east-1',
        access_key_id: access_key,
        secret_access_key: secret_key,
        endpoint: "https://#{host}",
        force_path_style: true,
        ssl_verify_peer: false
      )

      remote_files = {}
      continuation_token = nil

      loop do
        response = client.list_objects_v2(
          bucket: bucket,
          prefix: s3_prefix,
          continuation_token: continuation_token
        )

        response.contents.each do |object|
          next if object.key.end_with?('/')

          relative_path = object.key.sub(s3_prefix, '')
          body = client.get_object(
            bucket: bucket,
            key: object.key
          ).body.read

          remote_sha256 = Digest::SHA256.hexdigest(body)
          remote_files[relative_path] = remote_sha256
        end

        break unless response.is_truncated

        continuation_token = response.next_continuation_token
      end

      local_files = {}
      Dir.glob("#{local_path}/**/*", File::FNM_DOTMATCH).each do |path|
        next if File.directory?(path)

        relative_path = path.sub("#{local_path}/", '')
        local_sha256 = Digest::SHA256.file(path).hexdigest
        local_files[relative_path] = local_sha256
      end

      missing_local = []
      modified_files = []
      extra_local = []

      remote_files.each do |relative_path, remote_sha256|
        local_sha256 = local_files[relative_path]

        if local_sha256.nil?
          missing_local << relative_path
        elsif local_sha256 != remote_sha256
          modified_files << relative_path
        end
      end

      local_files.each do |relative_path|
        extra_local << relative_path unless remote_files.key?(relative_path)
      end

      sync_ok = missing_local.empty? && modified_files.empty? && extra_local.empty?

      unless sync_ok
        Chef::Log.info('HTTP Agent S3 synchronization issues detected. Syncronizing local files with S3...')
        syncronize_local_with_s3(missing_local, modified_files, extra_local, bucket, host, access_key, secret_key, local_path, s3_prefix)

        raise 'HTTP Agent S3 synchronization issues detected. Check logs for details.'
      end

      Chef::Log.info('HTTP Agent S3 synchronization check passed successfully.')

      true
    end

    def syncronize_local_with_s3(missing_local, modified_files, extra_local, bucket, host, access_key, secret_key, local_path, s3_prefix)
      client = Aws::S3::Client.new(
        region: 'us-east-1',
        access_key_id: access_key,
        secret_access_key: secret_key,
        endpoint: "https://#{host}",
        force_path_style: true,
        ssl_verify_peer: false
      )

      (missing_local + modified_files).each do |relative_path|
        s3_key = "#{s3_prefix}#{relative_path}"
        local_file_path = "#{local_path}/#{relative_path}"

        begin
          body = client.get_object(
            bucket: bucket,
            key: s3_key
          ).body.read

          FileUtils.mkdir_p(File.dirname(local_file_path))
          File.write(local_file_path, body)
          Chef::Log.info("Synchronized file from S3: #{relative_path}")
        rescue Aws::S3::Errors::NoSuchKey
          Chef::Log.error("File not found in S3 for synchronization: #{relative_path}")
        end
      end

      extra_local.each do |relative_path|
        local_file_path = "#{local_path}/#{relative_path}"
        File.delete(local_file_path) if File.exist?(local_file_path)
        Chef::Log.info("Removed extra local file not present in S3: #{relative_path}")
      end
  end
end
