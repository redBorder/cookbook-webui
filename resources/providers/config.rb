# Cookbook Name:: webui
#
# Provider:: config
#

action :add do #Usually used to install and configure something
  begin
    user = new_resource.user
    group = new_resource.group
    hostname = new_resource.hostname
    memory_kb = new_resource.memory_kb
    cdomain = new_resource.cdomain
    #elasticache_hosts = new_resource.elasticache_hosts
    http_workers = ([ [ 10 * node["cpu"]["total"].to_i, (memory_kb / (3*1024*1024)).floor ].min, 1 ].max).to_i

    ####################
    # INSTALLATION
    ####################

    yum_package "redborder-webui" do
      action :install
      flush_cache [:before]
      notifies :run, "execute[db_migrate]", :delayed
      notifies :run, "execute[db_migrate_modules]", :delayed
      notifies :run, "execute[db_seed]", :delayed
      notifies :run, "execute[db_seed_modules]", :delayed
      notifies :run, "execute[redBorder_generate_server_key]", :delayed
      notifies :run, "execute[redBorder_update]", :delayed
      notifies :run, "execute[assets_precompile]", :delayed
    end

    yum_package "redborder-webui" do
      action :upgrade
      flush_cache [:before]
      notifies :run, "execute[redBorder_update]", :delayed
    end

    user user do
      action :create
      system true
    end

    group group do
      action :create
      members user
      append true
    end

    # /var/www must to be created by the RPM

    directory "/var/www/rb-rails" do
      owner user
      group group
      mode 0755
      recursive true
      action :create
    end

    directory "/var/www/rb-rails/config" do
      owner user
      group group
      mode 0755
      recursive true
      action :create
    end

    directory "/var/www/rb-rails/tmp" do
      owner user
      group group
      mode 0755
      action :create
    end

    %w[ data tmp/pids tmp/delayed_job tmp/geodb public ].each do |x|
      directory "/var/www/rb-rails/#{x}" do
        owner user
        group group
        mode 0755
        action :create
      end
    end

    link "/var/log/rb-rails" do
      to "/var/www/rb-rails/log"
    end

    ##########
    # LICENSE
    ##########

    #link "/var/www/rb-rails/rB.lic" do
    #  to "/etc/redborder/rB.lic"
    #end

    #cookbook_file "/etc/redborder/rB.lic" do
    #  source "rB.lic"
    #  owner "root"
    #  group "root"
    #  mode "0644"
    #  cookbook "webui"
    #  action :create_if_missing
    #end

    ####################
    # READ DATABAGS
    ####################

    #Obtaining s3 data
    s3 = Chef::DataBagItem.load("passwords", "s3") rescue s3 = {}
    if !s3.empty?
      s3_bucket = s3["s3_bucket"]
      s3_host = s3["s3_host"]
      s3_access_key = s3["s3_access_key_id"]
      s3_secret_key = s3["s3_secret_key_id"]
    end

    #Obtaining redborder database configuration from databag
    db_redborder = Chef::DataBagItem.load("passwords", "db_redborder") rescue db_redborder = {}
    if !db_redborder.empty?
      db_name_redborder = db_redborder["database"]
      db_hostname_redborder = db_redborder["hostname"]
      db_port_redborder = db_redborder["port"]
      db_username_redborder = db_redborder["username"]
      db_pass_redborder = db_redborder["pass"]
    end

    #Obtaining druid database configuration from databag
    db_druid = Chef::DataBagItem.load("passwords", "db_druid") rescue db_druid = {}
    if !db_druid.empty?
      db_name_druid = db_druid["database"]
      db_hostname_druid = db_druid["hostname"]
      db_port_druid = db_redborder["port"]
      db_username_druid = db_druid["username"]
      db_pass_druid = db_druid["pass"]
    end

    webui_secret = Chef::DataBagItem.load("passwords", "webui_secret") rescue webui_secret = {}
    if !webui_secret.empty?
      webui_secret_token = webui_secret["secret"]
    end

    ############
    # TEMPLATES
    ############

    template "/var/www/rb-rails/config/aws.yml" do
        source "aws.yml.erb"
        owner user
        group group
        mode 0644
        retries 2
        cookbook "webui"
        variables(:s3_bucket => s3_bucket, :s3_host => s3_host,
                  :s3_access_key => s3_access_key, :s3_secret_key => s3_secret_key)
        notifies :restart, "service[webui]", :delayed
        #notifies :restart, "service[workers]", :delayed
    end

    template "/var/www/rb-rails/config/chef_config.yml" do
        source "chef_config.yml.erb"
        owner user
        group group
        mode 0644
        retries 2
        cookbook "webui"
        variables(:nodename => hostname)
        notifies :restart, "service[webui]", :delayed
        #notifies :restart, "service[workers]", :delayed
    end

    template "/var/www/rb-rails/config/database.yml" do
        source "database.yml.erb"
        owner user
        group group
        mode 0644
        retries 2
        cookbook "webui"
        notifies :restart, "service[webui]", :delayed
        #notifies :restart, "service[workers]", :delayed
        variables(:db_name_redborder => db_name_redborder, :db_hostname_redborder => db_hostname_redborder,
                  :db_port_redborder => db_port_redborder, :db_username_redborder => db_username_redborder,
                  :db_pass_redborder => db_pass_redborder, :db_name_druid => db_name_druid,
                  :db_hostname_druid => db_hostname_druid, :db_port_druid => db_port_druid,
                  :db_username_druid => db_username_druid, :db_pass_druid => db_pass_druid,
                  :http_workers => http_workers,
                  :memory => memory_kb)
    end

    template "/var/www/rb-rails/config/redborder_config.yml" do
        source "redborder_config.yml.erb"
        owner user
        group group
        mode 0644
        retries 2
        cookbook "webui"
        variables(:cdomain => cdomain,
                  :webui_secret_token => webui_secret_token)
                  #:proxy_insecure => proxy_insecure) #TODO when client proxy done. Set proxy_verify_cert in template
        notifies :restart, "service[webui]", :delayed
        #notifies :restart, "service[workers]", :delayed
    end

    template "/var/www/rb-rails/config/rbdruid_config.yml" do
        source "rbdruid_config.yml.erb"
        owner user
        group group
        mode 0644
        retries 2
        cookbook "webui"
        notifies :restart, "service[webui]", :delayed
    end

    #template "/var/www/rb-rails/config/memcached_config.yml" do
    #    source "memcached_config.yml.erb"
    #    owner "root"
    #    group "root"
    #    mode 0644
    #    retries 2
    #    cookbook "webui"
    #    variables(:elasticache_hosts => elasticache_hosts)
    #    #notifies :restart, "service[webui]", :delayed
    #end

    template "/var/www/rb-rails/config/databags.yml" do
        source "databags.yml.erb"
        owner user
        group group
        mode 0644
        retries 2
        cookbook "webui"
        notifies :restart, "service[webui]", :delayed
    end

    template "/var/www/rb-rails/config/modules.yml" do
        source "modules.yml.erb"
        owner user
        group group
        mode 0644
        retries 2
        cookbook "webui"
        notifies :restart, "service[webui]", :delayed
    end

    [ "flow", "ips", "location", "monitor", "social", "iot" ].each do |x|
        template "/var/www/rb-rails/lib/modules/#{x}/config/rbdruid_config.yml" do
            source "#{x}_rbdruid_config.yml.erb"
            owner user
            group group
            mode 0644
            retries 2
            cookbook "webui"
            notifies :restart, "service[webui]", :delayed
        end if Dir.exists?("/var/www/rb-rails/lib/modules/#{x}/config")
    end

    template "/var/www/rb-rails/config/unicorn.rb" do
        source "unicorn.rb.erb"
        owner user
        group group
        mode 0644
        retries 2
        cookbook "webui"
        variables(:workers => http_workers)
        notifies :restart, "service[webui]", :delayed
    end

    template "/etc/sysconfig/webui" do
        source "webui_sysconfig.erb"
        owner user
        group group
        mode 0644
        retries 2
        cookbook "webui"
        variables(:memory => memory_kb)
        notifies :restart, "service[webui]", :delayed
    end

    ############
    # RAKE TASKS
    ############

    execute "db_migrate" do
      command "rake db:migrate &>/dev/null"
      cwd "/var/www/rb-rails"
      environment "NO_MODULES" => "1"
      environment "RAILS_ENV" => "production"
      user user
      group group
      action :nothing
    end

    execute "db_migrate_modules" do
      command "rake db:migrate:modules &>/dev/null"
      cwd "/var/www/rb-rails"
      environment "NO_MODULES" => "1"
      environment "RAILS_ENV" => "production"
      user user
      group group
      action :nothing
    end

    execute "db_seed" do
      command "rake db:seed &>/dev/null"
      cwd "/var/www/rb-rails"
      environment "NO_MODULES" => "1"
      environment "RAILS_ENV" => "production"
      user user
      group group
      action :nothing
    end

    execute "db_seed_modules" do
      command "rake db:seed:modules &>/dev/null"
      cwd "/var/www/rb-rails"
      environment "RAILS_ENV" => "production"
      user user
      group group
      action :nothing
    end

    execute "redBorder_generate_server_key" do
      command "rake redBorder:generate_server_key &>/dev/null"
      cwd "/var/www/rb-rails"
      user user
      group group
      action :nothing
    end

    execute "redBorder_update" do
      command "rake redBorder:update &>/dev/null"
      cwd "/var/www/rb-rails"
      user user
      group group
      action :nothing
    end

    execute "assets_precompile" do
      command "rake assets:precompile &>/dev/null"
      cwd "/var/www/rb-rails"
      environment "RAILS_ENV" => "production"
      user user
      group group
      action :nothing
    end

    ############
    # SERVICES
    ############

    service "webui" do
      service_name "webui"
      supports :status => true, :reload => true, :restart => true, :enable => true
      action :nothing
    end

    service "webiu_workers" do
      service_name "webui_workers"
      supports :status => true, :reload => true, :restart => true, :enable => true
      action :nothing
    end

    Chef::Log.info("Webui cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do #Usually used to uninstall something
  begin
    web_dir = new_resource.web_dir

    yum_package 'redborder-webui' do
      action :remove
      notifies :stop, "service[webui]", :immediately
      #notifies :stop, "service[webui_workers]", :immediately
    end

    directory web_dir do
      recursive true
      action :delete
    end

    service "webui" do
      service_name "webui"
      supports :stop => true, :disable => true
      action :nothing
    end

    Chef::Log.info("Webui cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do
  begin
    if !node["webui"]["registered"]
      query = {}
      query["ID"] = "webui-#{node["hostname"]}"
      query["Name"] = "webui"
      query["Address"] = "#{node["ipaddress"]}"
      query["Port"] = 443
      json_query = Chef::JSONCompat.to_json(query)

      execute 'Register service in consul' do
         command "curl http://localhost:8500/v1/agent/service/register -d '#{json_query}' &>/dev/null"
         action :nothing
      end.run_action(:run)

      node.set["webui"]["registered"] = true
      Chef::Log.info("Webui service has been registered to consul")
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do
  begin
    if node["webui"]["registered"]
      execute 'Deregister service in consul' do
        command "curl http://localhost:8500/v1/agent/service/deregister/webui-#{node["hostname"]} &>/dev/null"
        action :nothing
      end.run_action(:run)

      node.set["webui"]["registered"] = false
      Chef::Log.info("Webui service has been deregistered from consul")
    end
  rescue => e
    Chef::Log.error(e.message)
  end
end
