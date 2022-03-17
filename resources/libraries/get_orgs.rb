module Rb_manager
  module Helpers
    def get_orgs()

      organizations = []

      Chef::Role.list.keys.each do |m_key|
        m = Chef::Role.load m_key
        if !m.override_attributes["redborder"].nil? and !m.override_attributes["redborder"]["organization_uuid"].nil? and m.override_attributes["redborder"]["sensor_uuid"] == m.override_attributes["redborder"]["organization_uuid"]
          organizations << m
        end
      end

      organizations

    end
  end
end

