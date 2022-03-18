module Rb_manager
  module Helpers
    def get_managers_all
      managers = []
      managers_keys = Chef::Node.list.keys.sort
      managers_keys.each do |m_key|
        m = Chef::Node.load m_key
        m = node if m.name == node.name
        begin
          roles = m.roles
        rescue NoMethodError
          begin
            roles = m.run_list
          rescue
            roles = []
          end
        end
        unless roles.nil?
          if roles.include?("manager")
            managers << m
          end
        end
      end
      managers
    end
  end
end