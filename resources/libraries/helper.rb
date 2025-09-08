module Webui
  module Helper
    require 'openssl'
    require 'resolv'
    require 'base64'
    require 'securerandom'

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
      cert.sign key, OpenSSL::Digest.new('SHA1')
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

    def manager_seeds(managers_names)
      seeds = managers_names.map do |n|
        node_obj =
          if n.is_a?(Hash)
            n
          else
            begin
              Chef::Node.load(n)
            rescue => e
              Chef::Log.warn("Could not load node #{n}: #{e.class}: #{e.message}")
              nil
            end
          end

        next unless node_obj

        host = node_obj['ipaddress_sync'] ||
               node_obj['ipaddress'] ||
               node_obj['fqdn'] ||
               (node_obj.respond_to?(:name) ? node_obj.name : node_obj['name'])

        port = (node_obj.dig('aerospike', 'port') || 3000).to_i

        host && port ? "#{host}:#{port}" : nil
      end

      seeds = seeds.compact.uniq.sort
      if seeds.empty?
        Chef::Log.warn('Aerospike seed list is empty. Check node attributes for managers.')
      end
      seeds
    end
  end
end
