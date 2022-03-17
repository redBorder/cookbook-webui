module Rb_manager
  module Helpers
    def get_cluster_info()
      cluster_info = {}
      manager_nodes = {}
  
      manager_nodes = search(:node, "recipes:rb-manager").sort

      #The search function above is looking for rb-manager value in "Recipes" key instead run_list, for this reason
      #in the first execution the node data is not added to managers hash, so it will be checked now and added 
      #to managers array
      if !cluster_info.key?(node.name) and node.recipe?("rb-manager") and !manager_nodes.include?(node)
        manager_nodes << node
      end

      manager_nodes.each do |mnode|
        name = mnode.name
        services = []
        # add active services to array
        mnode_services = mnode["redborder"]["services"].to_h
        mnode_services.each do |service, service_status|
          services << service if service_status
        end
        cluster_info[name] = {}
        cluster_info[name]["name"] = name
        cluster_info[name]["ip"] = mnode["ipaddress"]
        cluster_info[name]["services"] = services
      end

      return cluster_info
    end
  end
end
