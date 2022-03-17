module Rb_manager
  module Helpers
    def get_sensors_all_info()
      sensors_info = {}
      sensor_types = ["ips-sensor","ipsv2-sensor","ipscp-sensor","ipsg-sensor","vault-sensor","flow-sensor","mse-sensor","meraki-sensor","cisco-cloudproxy","proxy-sensor","social-sensor","scanner-sensor","mse-sensor","meraki-sensor","ale-sensor"]

      sensor_types.each do |s_type|
        sensors = search(:node, "role:#{s_type}").sort

        sensors_info[s_type] = []
        sensors.each do |s|
          sensors_info[s_type] << s
        end
      end
      sensors_info
    end
  end
end
