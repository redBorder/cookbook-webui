module Rb_manager
  module Helpers

    require 'timeout'
    require 'socket'

    def getElasticacheNodes(config_endpoint, port)
      begin
        socket = TCPSocket.new config_endpoint, port
        response = []
        status = Timeout::timeout(2) {
          finish = true
          socket.puts("config get cluster")
          while finish
            response.push(socket.gets.chomp)
            finish = false if "#{response.last}" == "END"
          end
        }
        socket.close
        nodes = response.at(2).split(" ").map {
            |server|
            server.split("|").at(0)
        }
        return nodes
      rescue => e
        Chef::Log.error(e.message)
      end
    end
  end
end
