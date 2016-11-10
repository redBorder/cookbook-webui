# Cookbook Name:: webui
#
# Provider:: config
#

action :add do #Usually used to install and configure something
  begin
    user = new_resource.user

    yum_package "redborder-webui" do #TODO Lo instala en /var/www/rb-rails
      action :upgrade
      flush_cache [:before]
    end

    user user do
      action :create
      system true
    end

    # /var/www debe crearlo el RPM

    directory "/var/www/rb-rails" do
      owner "root"
      group "root"
      mode 0755
      recursive true
      action :create
    end

    directory "/var/www/rb-rails/config" do
      owner "webui"
      group "webui"
      mode 0755
      recursive true
      action :create
    end

    directory "/var/www/rb-rails/tmp" do
      owner "webui"
      group "webui"
      mode 0755
      action :create
    end

    [ "data", "tmp/pids", "tmp/delayed_job", "tmp/geodb", "public" ].each do |x|
      directory "/var/www/rb-rails/#{x}" do
        owner "webui"
        group "webui"
        mode 0755
        action :create
      end if !Dir.exists? "/var/www/rb-rails/#{x}"
    end

    link "/var/www/rb-rails/log" do
      to "/var/log/rb-rails"
    end if !File.exists? "/var/www/rb-rails/log"

    ##########
    # LICENSE
    ##########

    link "/var/www/rb-rails/rB.lic" do
      to "/etc/rB.lic"
    end if !File.exists? "/var/www/rb-rails/rB.lic"

    if !File.exist? "/etc/rB.lic"
      cookbook_file "/etc/rB.lic" do
        source "rB.lic"
        owner "root"
        group "root"
        mode "0644"
        cookbook "webui"
      end
    end

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

    #Obtaining druid database configuration from databag
    db_druid = Chef::DataBagItem.load("passwords", "db_redborder") rescue db_druid = {}
    if !db_druid.empty?
      psql_uri = "#{db_redborder["hostname"]}:#{db_redborder["port"]}"
      psql_user = db_redborder["username"]
      psql_password = db_redborder["pass"]
    end

    ############
    # TEMPLATES
    ############

    template "/var/www/rb-rails/config/aws.yml" do
        source "aws.yml.erb"
        owner "root"
        group "root"
        mode 0644
        retries 2
        cookbook "webui"
        variables(:s3_bucket => s3_bucket, :s3_host => s3_host, :s3_access_key => s3_access_key, :s3_secret_key => s3_secret_key)
        notifies :restart, "service[webui]", :delayed
        notifies :restart, "service[workers]", :delayed
    end

    template "/var/www/rb-rails/config/chef_config.yml" do
        source "chef_config.yml.erb"
        owner "root"
        group "root"
        mode 0644
        retries 2
        cookbook "webui"
        variables(:nodename => node["hostname"])
        notifies :restart, "service[webui]", :delayed
        notifies :restart, "service[workers]", :delayed
    end

    service "webui" do
      service_name "webui"
      supports :status => true, :reload => true, :restart => true, :enable => true
      action :nothing
    end

    service "workers" do
      service_name "workers"
      supports :status => true, :reload => true, :restart => true, :enable => true
      action :nothing
    end

    Chef::Log.info("Example cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :remove do #Usually used to uninstall something
  begin
     # ... your code here ...
     Chef::Log.info("Example cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :register do #Usually used to register in consul
  begin
     # ... your code here ...
     Chef::Log.info("Example cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end

action :deregister do #Usually used to deregister from consul
  begin
     # ... your code here ...
     Chef::Log.info("Example cookbook has been processed")
  rescue => e
    Chef::Log.error(e.message)
  end
end
