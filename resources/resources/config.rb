# Cookbook Name:: webui
#
# Resource:: config
#

actions :add, :remove, :register, :deregister, :configure_db, :configure_rsa, :configure_certs
default_action :add

attribute :user, :kind_of => String, :default => "webui"
attribute :group, :kind_of => String, :default => "webui"
attribute :port, :kind_of => Integer, :default => 8001
attribute :hostname, :kind_of => String
attribute :cdomain, :kind_of => String, :default => "redborder.cluster"
attribute :web_dir, :kind_of => String, :default => "/var/www/rb-rails"
attribute :memory_kb, :kind_of => Integer
attribute :elasticache_hosts, :kind_of => Object
attribute :zk_hosts, :kind_of => String
