class Chef
  class Recipe
    def managers_per_service()
      services = node["redborder"]["services"]
      cluster_info = node["redborder"]["cluster_info"] 
      cluster_services = {}

      services.each do |serv, status|
        cluster_services[serv] = []
        cluster_info.each do |manager, info|
          if !info["services"].nil? and info["services"].include?(serv)
            cluster_services[serv] << manager 
          end
        end
      end
      return cluster_services
    end
  end
end
