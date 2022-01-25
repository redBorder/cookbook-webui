#
# Cookbook Name:: webui
# Recipe:: default
#
# Copyright 2016, redborder
#
# All rights reserved - Do Not Redistribute
#

webui_config "config" do
  hostname node["hostname"]
  action [:add, :register, :configure_rsa]
end
