# Cookbook:: webui
# Provider:: config

include Webui::Helper

action :add do
  begin
    user = new_resource.user
    group = new_resource.group
    hostname = new_resource.hostname
    webui_version = new_resource.webui_version
    redborder_version = new_resource.redborder_version
    memory_kb = new_resource.memory_kb
    cdomain = new_resource.cdomain
    s3_local_storage = new_resource.s3_local_storage
    elasticache_hosts = new_resource.elasticache_hosts
    memcached_servers = new_resource.memcached_servers
    http_workers = [[10 * node['cpu']['total'].to_i, (memory_kb / (3 * 1024 * 1024)).floor ].min, 1].max.to_i
    auth_mode = new_resource.auth_mode
    auth_mode = 'saml' if node['redborder']['sso_enabled'] == '1'
    user_sensor_map = new_resource.user_sensor_map
    web_dir = new_resource.web_dir
    s3_secrets = new_resource.s3_secrets

    # INSTALLATION
    # begin
    #   licmode_dg = data_bag_item('rBglobal', 'licmode')
    # rescue
    #   licmode_dg = {}
    # end
    # licmode = licmode_dg['mode']
    # if licmode != 'global' && licmode != 'organization'
    #   licmode = 'global' if (licmode != 'global' && licmode != 'organization')
    # end

    dnf_package 'redborder-webui' do
      action :install
      notifies :run, 'bash[run_ditto]', :delayed
      notifies :run, 'bash[db_migrate]', :delayed
      notifies :run, 'bash[db_migrate_modules]', :delayed
      notifies :run, 'bash[assets_precompile]', :delayed
      # notifies :run, 'bash[create_license_databag]', :delayed
      # notifies :run, 'bash[db_seed]', :delayed
      # notifies :run, 'bash[db_seed_modules]', :delayed
      # notifies :run, 'bash[redBorder_generate_server_key]', :delayed
      # notifies :run, 'bash[redBorder_update]', :delayed
      # notifies :run, 'bash[request_trial_license]', :delayed
    end

    dnf_package 'redborder-webui' do
      action :upgrade
      notifies :run, 'bash[run_ditto]', :delayed
      notifies :run, 'bash[db_migrate]', :delayed
      notifies :run, 'bash[db_migrate_modules]', :delayed
      notifies :run, 'bash[db_seed]', :delayed
      notifies :run, 'bash[db_seed_modules]', :delayed
      notifies :run, 'bash[clean_assets]', :delayed
      notifies :run, 'bash[assets_precompile]', :delayed
      notifies :run, 'bash[redBorder_generate_server_key]', :delayed
      notifies :run, 'bash[redBorder_update]', :delayed
      notifies :run, 'bash[request_trial_license]', :delayed
    end

    dnf_package 'redborder-nodenvm' do
      action :upgrade
      notifies :restart, 'service[webui]', :delayed
    end

    dnf_package 'redborder-webui-node-modules' do
      action :upgrade
      notifies :restart, 'service[webui]', :delayed
    end

    file '/root/.upgrade-redborder-webui' do
      action :nothing
    end

    execute 'upgrade redborder-webui' do
      command 'echo $(date) >> /root/.upgrade-redborder-webui-date'
      notifies :run, 'bash[run_ditto]', :delayed
      notifies :run, 'bash[db_migrate]', :delayed
      notifies :run, 'bash[db_migrate_modules]', :delayed
      notifies :run, 'bash[db_seed]', :delayed
      notifies :run, 'bash[db_seed_modules]', :delayed
      notifies :run, 'bash[clean_assets]', :delayed
      notifies :run, 'bash[assets_precompile]', :delayed
      notifies :run, 'bash[redBorder_update]', :delayed
      only_if { ::File.exist?('/root/.upgrade-redborder-webui') }
      notifies :delete, 'file[/root/.upgrade-redborder-webui]', :immediately
      ignore_failure true
    end

    execute 'create_user' do
      command "/usr/sbin/useradd -r #{user}"
      ignore_failure true
      not_if "getent passwd #{user}"
    end

    directory '/var/www/rb-rails' do
      owner user
      group group
      mode '0755'
      recursive true
      action :create
    end

    directory '/var/www/rb-rails/config' do
      owner user
      group group
      mode '0755'
      recursive true
      action :create
    end

    directory '/var/www/rb-rails/tmp' do
      owner user
      group group
      mode '0755'
      action :create
    end

    directory '/var/www/redborder-llm' do
      owner user
      group group
      mode '0755'
      action :create
    end

    directory '/var/www/redborder-llm/cache/' do
      owner user
      group group
      mode '0755'
      action :create
    end

    %w(data tmp/pids tmp/delayed_job tmp/geodb public).each do |x|
      directory "/var/www/rb-rails/#{x}" do
        owner user
        group group
        mode '0755'
        action :create
      end
    end

    # Directories for download snort rules
    %w(snortrules snortrules/cache snortrules/so_rules snortrules/gen_msg).each do |x|
      directory "/var/www/#{x}" do
        owner user
        group group
        mode '0755'
        action :create
      end
    end

    link '/var/log/rb-rails' do
      to '/var/www/rb-rails/log'
    end

    link '/root/rb-rails' do
      to '/var/www/rb-rails'
    end

    # LICENSE
    cookbook_file '/etc/license.key.pub' do
      source 'license.key.pub'
      owner 'root'
      group 'root'
      mode '0644'
      retries 2
      cookbook 'webui'
      action :create_if_missing
    end

    cookbook_file '/var/www/rb-rails/config/license.key.pub' do
      source 'license.key.pub'
      owner user
      group user
      mode '0644'
      retries 2
      cookbook 'webui'
      action :create_if_missing
      notifies :restart, 'service[webui]', :delayed
    end

    # RB-EXTENSIONS
    directory '/var/www/plugins' do
      owner user
      group group
      mode '0755'
      action :create
    end

    directory '/var/www/plugins/plugins' do
      owner user
      group group
      mode '0755'
      action :create
    end

    directory '/var/www/plugins/cache' do
      owner user
      group group
      mode '0755'
      action :create
    end

    # link '/var/www/rb-rails/rB.lic' do
    #   to '/etc/redborder/rB.lic'
    # end

    # cookbook_file '/etc/redborder/rB.lic' do
    #   source 'rB.lic'
    #   owner 'root'
    #   group 'root'
    #   mode '0644'
    #   cookbook 'webui'
    #   action :create_if_missing
    # end

    unless s3_secrets.empty?
      s3_bucket = s3_secrets['s3_bucket']
      s3_host = s3_secrets['s3_host']
      s3_access_key = s3_secrets['s3_access_key_id']
      s3_secret_key = s3_secrets['s3_secret_key_id']
    end

    # Obtaining redborder database configuration from databag
    begin
      db_redborder = data_bag_item('passwords', 'db_redborder')
    rescue
      db_redborder = {}
    end

    unless db_redborder.empty?
      db_name_redborder = db_redborder['database']
      db_hostname_redborder = db_redborder['hostname']
      db_port_redborder = db_redborder['port']
      db_username_redborder = db_redborder['username']
      db_pass_redborder = db_redborder['pass']
    end

    # Obtaining druid database configuration from databag
    begin
      db_druid = data_bag_item('passwords', 'db_druid')
    rescue
      db_druid = {}
    end

    unless db_druid.empty?
      db_name_druid = db_druid['database']
      db_hostname_druid = db_druid['hostname']
      db_port_druid = db_redborder['port']
      db_username_druid = db_druid['username']
      db_pass_druid = db_druid['pass']
    end

    # Obtaining radius database configuration from databag
    begin
      db_radius = data_bag_item('passwords', 'db_radius')
    rescue
      db_radius = {}
    end

    unless db_radius.empty?
      db_name_radius = db_radius['database']
      db_hostname_radius = db_radius['hostname']
      db_port_radius = db_radius['port']
      db_username_radius = db_radius['username']
      db_pass_radius = db_radius['pass']
    end

    begin
      webui_secret = data_bag_item('passwords', 'webui_secret')
    rescue
      webui_secret = {}
    end

    unless webui_secret.empty?
      webui_secret_token = webui_secret['secret']
    end

    # TEMPLATES
    template '/var/www/rb-rails/config/aws.yml' do
      source 'aws.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      variables(s3_local_storage: s3_local_storage, s3_bucket: s3_bucket, s3_host: s3_host,
                s3_access_key: s3_access_key, s3_secret_key: s3_secret_key)
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
      notifies :restart, 'service[rb-workers]', :delayed unless node['redborder']['leader_configuring']
    end

    template '/var/www/rb-rails/config/chef_config.yml' do
      source 'chef_config.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      variables(nodename: hostname, cdomain: cdomain)
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
      notifies :restart, 'service[rb-workers]', :delayed unless node['redborder']['leader_configuring']
    end

    template '/var/www/rb-rails/config/database.yml' do
      source 'database.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
      notifies :restart, 'service[rb-workers]', :delayed unless node['redborder']['leader_configuring']
      variables(db_name_redborder: db_name_redborder, db_hostname_redborder: db_hostname_redborder,
                db_port_redborder: db_port_redborder, db_username_redborder: db_username_redborder,
                db_pass_redborder: db_pass_redborder,
                db_name_druid: db_name_druid, db_hostname_druid: db_hostname_druid,
                db_port_druid: db_port_druid, db_username_druid: db_username_druid,
                db_pass_druid: db_pass_druid,
                db_name_radius: db_name_radius, db_hostname_radius: db_hostname_radius,
                db_port_radius: db_port_radius, db_username_radius: db_username_radius,
                db_pass_radius: db_pass_radius,
                http_workers: http_workers,
                memory: memory_kb)
    end

    if webui_version
      template '/var/www/rb-rails/webui_version' do
        source 'webui_version.erb'
        owner user
        group group
        mode '0644'
        retries 2
        cookbook 'webui'
        variables(webui_version: webui_version)
      end
    end

    if hostname
      template '/var/www/rb-rails/hostname' do
        source 'hostname.erb'
        owner user
        group group
        mode '0644'
        retries 2
        cookbook 'webui'
        variables(hostname: hostname)
      end
    end

    if redborder_version
      template '/var/www/rb-rails/version' do
        source 'version.erb'
        owner user
        group group
        mode '0644'
        retries 2
        cookbook 'webui'
        variables(redborder_version: redborder_version)
      end
    end

    template '/var/www/rb-rails/config/redborder_config.yml' do
      source 'redborder_config.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      variables(cdomain: cdomain,
                webui_secret_token: webui_secret_token,
                auth_mode: auth_mode)
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
      notifies :restart, 'service[rb-workers]', :delayed unless node['redborder']['leader_configuring']
    end

    template '/var/www/rb-rails/config/rbdruid_config.yml' do
      source 'rbdruid_config.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
    end

    template '/var/www/rb-rails/config/memcached_config.yml' do
      source 'memcached_config.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      variables(elasticache_hosts: elasticache_hosts, memcached_servers: memcached_servers)
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
    end

    template '/var/www/rb-rails/config/plugins_config.yml' do
      source 'plugins_config.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
    end

    template '/var/www/rb-rails/config/databags.yml' do
      source 'databags.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
    end

    template '/var/www/rb-rails/config/modules.yml' do
      source 'modules.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
    end

    template '/var/www/rb-rails/config/licenses.yml' do
      source 'licenses.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
    end

    %w(flow ips location monitor iot).each do |x|
      template "/var/www/rb-rails/lib/modules/#{x}/config/rbdruid_config.yml" do
        source "#{x}_rbdruid_config.yml.erb"
        owner user
        group group
        mode '0644'
        retries 2
        cookbook 'webui'
        notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
      end if Dir.exist?("/var/www/rb-rails/lib/modules/#{x}/config")
    end

    template '/var/www/rb-rails/config/unicorn.rb' do
      source 'unicorn.rb.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      variables(workers: http_workers)
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
    end

    template '/etc/sysconfig/webui' do
      source 'webui_sysconfig.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      variables(memory: memory_kb)
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
    end

    begin
      rsa_pem = data_bag_item('certs', 'rsa_pem')
    rescue
      rsa_pem = nil
    end

    if rsa_pem && rsa_pem['private_rsa']
      template '/var/www/rb-rails/config/rsa' do
        source 'rsa_cert.pem.erb'
        owner user
        group group
        mode '0600'
        retries 2
        cookbook 'webui'
        notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
        notifies :restart, 'service[rb-workers]', :delayed unless node['redborder']['leader_configuring']
        variables(private_rsa: rsa_pem['private_rsa'])
      end
    end

    template '/var/www/rb-rails/config/sso_user_sensor_map.yml' do
      source 'sso_user_sensor_map.yml.erb'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      variables(user_sensor_map: user_sensor_map)
      notifies :restart, 'service[webui]', :delayed unless node['redborder']['leader_configuring']
    end

    # LOG ROTATION
    template '/etc/logrotate.d/webui' do
      source 'webui_log-rotate.erb'
      owner 'root'
      group 'root'
      mode '0644'
      retries 2
      cookbook 'webui'
      variables(web_dir: web_dir)
    end

    directory '/var/www/rb-rails/log/rotated' do
      owner user
      group group
      mode '0755'
      action :create
      recursive true
    end

    # DASHBOARDS
    directory '/var/www/rb-rails/files/dashboards' do
      owner user
      group group
      mode '0755'
      recursive true
      action :create
    end

    # default.tar.gz is a default dashboard from a old version
    cookbook_file '/var/www/rb-rails/files/dashboards/default.tar.gz' do
      source 'default-dashboard.tar.gz'
      owner user
      group group
      mode '0644'
      retries 2
      cookbook 'webui'
      backup false
      ignore_failure true
    end

    # RAKE TASKS and OTHERS
    bash 'run_ditto' do
      ignore_failure false
      code <<-EOH
          source /etc/profile.d/rvm.sh
          export HOME=/var/www/rb-rails
          pushd /var/www/rb-rails &>/dev/null
          echo "### `date` - COMMAND: dittoc -r -o -f --allow-views ENTERPRISE /var/www/rb-rails/" &>>/var/www/rb-rails/log/install-redborder-ditto.log
          rvm ruby-2.7.5@web do dittoc -r -o -f --allow-views ENTERPRISE /var/www/rb-rails/ &>>/var/www/rb-rails/log/install-redborder-ditto.log
          popd &>/dev/null
        EOH
      user user
      group group
      action :nothing
    end

    bash 'db_migrate' do
      ignore_failure false
      code execute_rake_task(
        'db:migrate',
        'install-redborder-db.log',
        web_dir,
        { 'NO_MODULES' => 1, 'RAILS_ENV' => 'production' }
      )
      user user
      group group
      action :nothing
    end

    bash 'db_migrate_modules' do
      ignore_failure false
      code execute_rake_task(
        'db:migrate:modules',
        'install-redborder-db.log',
        web_dir,
        { 'NO_MODULES' => 1, 'RAILS_ENV' => 'production' }
      )
      user user
      group group
      action :nothing
    end

    bash 'db_seed' do
      ignore_failure false
      code execute_rake_task(
        'db:seed',
        'install-redborder-db.log',
        web_dir,
        { 'NO_MODULES' => 1, 'RAILS_ENV' => 'production' }
      )
      user user
      group group
      action :nothing
    end

    bash 'db_seed_modules' do
      ignore_failure false
      code execute_rake_task(
        'db:seed:modules',
        'install-redborder-db.log',
        web_dir,
        { 'RAILS_ENV' => 'production' }
      )
      user user
      group group
      action :nothing
    end

    bash 'clean_assets' do
      ignore_failure false
      code execute_rake_task(
        'assets:clean[0]',
        'install-redborder-assets.log',
        '/root',
        { 'RAILS_ENV' => 'production' }
      )
      user 'root'
      group 'root'
      action :nothing
    end

    bash 'assets_precompile' do
      ignore_failure false
      code <<-EOH
        #{execute_rake_task('assets:precompile', 'install-redborder-assets.log', '/root', { 'RAILS_ENV' => 'production' })}
        chown webui:webui -R /var/www/rb-rails
      EOH
      user 'root'
      group 'root'
      action :nothing
    end

    bash 'redBorder_generate_server_key' do
      ignore_failure false
      code execute_rake_task(
        'redBorder:generate_server_key',
        'install-redborder-server-key.log',
        web_dir
      )
      user user
      group group
      only_if { !::File.exist?('/var/www/rb-rails/log/install-redborder-server-key.log') && node['redborder']['leader_configuring'] }
      action :nothing
    end

    bash 'redBorder_update' do
      ignore_failure false
      code execute_rake_task(
        'redBorder:update',
        'install-redborder-server-key.log',
        web_dir
      )
      user user
      group group
      action :nothing
    end

    bash 'request_trial_license' do
      ignore_failure false
      code execute_rake_task(
        'redBorder:request_trial_license',
        'install-redborder-license.log',
        web_dir
      )
      user user
      group group
      only_if { !::File.exist?('/var/www/rb-rails/log/install-redborder-license.log') && node['redborder']['leader_configuring'] }
      notifies :stop, 'service[webui]', :delayed
      notifies :stop, 'service[rb-workers]', :delayed
      action :nothing
    end

    bash 'manage_delayed_jobs' do
      ignore_failure false
      code execute_rake_task(
        'redBorder:manage_jobs',
        'redborder-worker-logs.log',
        web_dir,
        { 'RAILS_ENV' => 'production' }
      )
      only_if { !node['redborder']['leader_configuring'] }
      user 'root'
      group 'root'
      action :run
    end

    # SERVICES
    service 'webui' do
      service_name 'webui'
      supports status: true, reload: true, restart: true, enable: true, start: true, stop: true
      if node['redborder']['leader_configuring']
        action [:enable, :stop]
      else
        action [:enable, :start]
      end
    end

    service 'rb-workers' do
      service_name 'rb-workers'
      supports status: true, restart: true, enable: true, stop: true
      if node['redborder']['leader_configuring']
        action [:enable, :stop]
      else
        action [:enable, :start]
      end
    end

    Chef::Log.info('Webui cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :add_webui_conf_nginx do
  begin
    webui_port = new_resource.port
    webui_hosts = new_resource.hosts
    routes = local_routes()
    cdomain = new_resource.cdomain

    service 'nginx' do
      service_name 'nginx'
      supports status: true, reload: true, restart: true, enable: true
      action :nothing
    end

    template '/etc/nginx/conf.d/webui.conf' do
      source 'webui.conf.erb'
      owner 'nginx'
      group 'nginx'
      mode '0644'
      cookbook 'webui'
      variables(webui_hosts: webui_hosts, webui_port: webui_port, cdomain: cdomain)
      notifies :restart, 'service[nginx]'
    end

    template '/etc/nginx/conf.d/redirect.conf' do
      source 'redirect.conf.erb'
      owner 'nginx'
      group 'nginx'
      mode '0644'
      cookbook 'webui'
      variables(routes: routes)
      notifies :restart, 'service[nginx]'
    end

    Chef::Log.info('nginx webui configuration has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :configure_certs do
  begin
    cdomain = new_resource.cdomain

    service 'nginx' do
      service_name 'nginx'
      supports status: true, reload: true, restart: true, enable: true
      action :nothing
    end

    webui_crt, webui_key = nil
    webui_external_json_cert = nginx_certs('webui_external')

    if webui_external_json_cert && !webui_external_json_cert.empty?
      webui_crt = webui_external_json_cert['webui_external_crt']
      webui_key = webui_external_json_cert['webui_external_key']
    end

    unless webui_crt && webui_key
      webui_json_cert = nginx_certs('webui', cdomain)
      webui_crt = webui_json_cert['webui_crt']
      webui_key = webui_json_cert['webui_key']
    end

    nginx_certs('saml', cdomain)

    template '/etc/nginx/ssl/webui.crt' do
      source 'cert.crt.erb'
      owner 'nginx'
      group 'nginx'
      mode '0644'
      retries 2
      cookbook 'webui'
      not_if { webui_crt.nil? || webui_crt.empty? }
      variables(crt: webui_crt)
      action :create
      notifies :restart, 'service[nginx]', :delayed
    end

    template '/etc/nginx/ssl/webui.key' do
      source 'cert.key.erb'
      owner 'nginx'
      group 'nginx'
      mode '0644'
      retries 2
      cookbook 'webui'
      not_if { webui_key.nil? || webui_key.empty? }
      variables(key: webui_key)
      action :create
      notifies :restart, 'service[nginx]', :delayed
    end

    Chef::Log.info('Certs for service webui have been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do
  begin
    # web_dir = new_resource.web_dir

    # dnf_package 'redborder-webui' do
    #   action :remove
    #   notifies :stop, 'service[webui]', :immediately
    #   notifies :stop, 'service[rb-workers]', :immediately
    #   notifies :disable, 'service[webui]', :immediately
    #   notifies :disable, 'service[rb-workers]', :immediately
    # end

    # directory web_dir do
    #   recursive true
    #   action :delete
    # end

    service 'webui' do
      service_name 'webui'
      supports stop: true, disable: true
      action [:stop, :disable]
    end

    service 'rb-workers' do
      service_name 'rb-workers'
      supports stop: true, disable: true
      action [:stop, :disable]
    end

    Chef::Log.info('Webui cookbook has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    unless node['webui']['registered']
      query = {}
      query['ID'] = "webui-#{node['hostname']}"
      query['Name'] = 'webui'
      query['Address'] = "#{node['ipaddress']}"
      query['Port'] = 443
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['webui']['registered'] = true
      Chef::Log.info('Webui service has been registered to consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    if node['webui']['registered']
      execute 'Deregister service in consul' do
        command "curl -X PUT http://localhost:8500/v1/agent/service/deregister/webui-#{node['hostname']} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.normal['webui']['registered'] = false
      Chef::Log.info('Webui service has been deregistered from consul')
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :configure_rsa do
  begin
    rsa_pem = data_bag_item('certs', 'rsa_pem')
  rescue
    rsa_pem = nil
  end

  begin
    ssh_secrets = data_bag_item('passwords', 'ssh')
  rescue
    ssh_secrets = nil
  end

  begin
    if rsa_pem
      if ssh_secrets
        file '/var/www/rb-rails/config/rsa.pub' do
          content ssh_secrets['public_rsa']
          owner 'webui'
          group 'webui'
          mode '0644'
          action :create
        end
      end
    else
      execute 'Check RSA certificate' do
        command '/usr/lib/redborder/bin/rb_create_rsa.sh -f'
        action :nothing
      end.run_action(:run)
    end
    Chef::Log.info('Webui cookbook - RSA cert has been processed')
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :configure_modules do
  begin
    user = new_resource.user
    group = new_resource.group

    bash 'set_modules' do
      ignore_failure true
      code <<-EOH
        rvm ruby-2.7.5@global do /usr/lib/redborder/bin/rb_set_modules bi:0 malware:0
      EOH
      user user
      group group
      action :run
      notifies :restart, 'service[webui]', :delayed
    end

    service 'webui' do
      service_name 'webui'
      supports status: true, reload: true, restart: true, enable: true
      action :nothing
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end
