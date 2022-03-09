module Rb_manager
  module Helpers
    def node_services(rbnode)
      if !rbnode.nil? and !rbnode.empty?
        rbnodes_arr = []
        rbnodes_arr = search(:node, "name:#{rbnode}")
        if rbnodes_arr.length == 1
           rbnode_attributes = rbnodes_arr.first
           services = []
           node["redborder"]["services"].each do |service, service_status|
             services << service if service_status
           end
           return services
        else
          raise "ERROR: There are two nodes with the same name, Im not able to get the #{manager} services."
        end
      end
    end
  end
end
