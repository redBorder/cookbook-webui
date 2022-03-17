module Rb_manager
  module Helpers
    def get_namespaces
      namespaces = []
      Chef::Role.list.keys.each do |rol|
        ro = Chef::Role.load rol
        if ro and ro.override_attributes["redborder"] and ro.override_attributes["redborder"]["namespace"] and ro.override_attributes["redborder"]["namespace_uuid"] and !ro.override_attributes["redborder"]["namespace_uuid"].empty?
          namespaces.push(ro.override_attributes["redborder"]["namespace_uuid"])
        end
      end
      namespaces.uniq
    end
  end
end