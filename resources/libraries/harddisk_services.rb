module Rb_manager
  module Helpers
    def harddisk_services()
      hd_services = {}

      root_dev=node["redborder"]["manager"]["data_dev"]["root"]
      raw_dev=node["redborder"]["manager"]["data_dev"]["raw"]
      aggregate_dev=node["redborder"]["manager"]["data_dev"]["aggregate"]
      
      root_dev=node["filesystem"].keys.first if node["filesystem"][root_dev].nil?
      if node["filesystem"][raw_dev].nil? and node["filesystem"][aggregate_dev].nil?
        raw_dev=root_dev
        aggregate_dev=root_dev
      elsif node["filesystem"][raw_dev].nil?
        raw_dev=aggregate_dev
      elsif node["filesystem"][aggregate_dev].nil?
        aggregate_dev=raw_dev
      end
      
      hd_services_dev = {}
      hd_services_dev["root"]      = root_dev
      hd_services_dev["raw"]       = raw_dev
      hd_services_dev["aggregate"] = aggregate_dev
      
      hd_services_size = {}
      hd_services_size[root_dev]     =0
      hd_services_size[raw_dev]      =0
      hd_services_size[aggregate_dev]=0
      
      hd_services_size_total = {}
      hd_services_size_total[root_dev]      = 0
      hd_services_size_total[raw_dev]       = 0
      hd_services_size_total[aggregate_dev] = 0
      
      maxsize = {}
      hd_services_dev.each do |type, device|
        if node["filesystem"][device].nil?
          maxsize[type] = 300000000000
        else
          if node["filesystem"][device]["kb_size"].nil? and !node["filesystem"][hd_services_dev["root"]]["kb_size"].nil?
            maxsize[type] = node["filesystem"][hd_services_dev["root"]]["kb_size"].to_i*1024
          else
            maxsize[type] = node["filesystem"][device]["kb_size"].to_i*1024
          end
        end
        maxsize[type] = maxsize[type] - 7*1024*1024*1024 if device==hd_services_dev["root"]
        maxsize[type] = 0 if maxsize[type]<0
      end
      
      node["redborder"]["manager"]["hd_services"].each do |s|
        if node["redborder"]["services"][s[:name]]
          hd_services_size[hd_services_dev[s[:prefered]]] = hd_services_size[hd_services_dev[s[:prefered]]] + s[:count]
        end
        hd_services_size_total[hd_services_dev[s[:prefered]]] = hd_services_size_total[hd_services_dev[s[:prefered]]] + s[:count]
      end
      
      node["redborder"]["manager"]["hd_services"].each do |s|

        if hd_services_size[hd_services_dev[s[:prefered]]]>0 
          size = hd_services_size[hd_services_dev[s[:prefered]]]
        else
          if hd_services_size_total[hd_services_dev[s[:prefered]]]>0
            size = hd_services_size_total[hd_services_dev[s[:prefered]]]
          else
            size =1      
          end
        end
        hd_services[s[:name]] = ((s[:count].to_i * maxsize[s[:prefered]].to_i * 0.90)/size) / 1024 * 1024
      end 
      return hd_services
    end
  end
end
