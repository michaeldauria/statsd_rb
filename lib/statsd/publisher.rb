module Statsd
  class Publisher < EM::Connection

    def initialize(server)
      @server = server
    end

    def post_init
      data = @server.aggregate!
      send_data(data)
      close_connection_after_writing

      begin
        @server.notify!(data) if @server.config['rules']
      rescue Exception => e
        puts e
        puts e.backtrace
      end
    end
  end
end
