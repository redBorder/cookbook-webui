class Chef
  class Recipe
    def manager_services()
      manager_services  = {}
      node["redborder"]["services"].each { |k,v| manager_services[k] = v if (v==true or v==false) } if !node["redborder"]["services"].nil?
      
      # changing default values in case of the user has modify them
      node["redborder"]["services"]["overwrite"].each { |k,v| manager_services[k] = v if (v==true or v==false) } if !node["redborder"]["services"]["overwrite"].nil?
      
      return manager_services
    end
  end
end