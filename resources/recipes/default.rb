# Cookbook:: webui
# Recipe:: default
# Copyright:: 2024, redborder
# License:: Affero General Public License, Version 3

webui_config 'config' do
  hostname node['hostname']
  action :add
end
