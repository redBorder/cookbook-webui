# Cookbook Name:: webui
#
# Resource:: config
#

actions :add, :remove, :register, :deregister
default_action :add

attribute :user, :kind_of => String, :default => "webui"
attribute :hostname, :kind_of => String
attribute :memory_kb, :kind_of => Integer

#attribute :mystring, :kind_of => String, :default => "string example"
#attribute :myinteger, :kind_of => Fixnum, :default => 1
#attribute :myarray, :kind_of => Array, :default => ["val1"]
#attribute :myhash, :kind_of => Object, :default => {"val1" => "1"}
#attribute :myboolean, :kind_of => [TrueClass, FalseClass], :default => true
