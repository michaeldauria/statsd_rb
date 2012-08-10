module Statsd
  class Notifier::Campfire
    def initialize(app_name, config)
      @app_name = app_name
      @config = config
    end

    def send!(messages)
      @config[:room_ids].each do |room_id|
        http = EventMachine::HttpRequest.new(campfire_create_message_url(room_id)).post({
          head: {
            'authorization' => [@config[:api_token], 'X'],
            'content-type' => 'text/xml'
          },
          body: campfire_message(@app_name, messages)
        })
      end
    end

    private

    def campfire_create_message_url(room_id)
      'https://%s.campfirenow.com/room/%s/speak.xml' % [ @config[:subdomain], room_id ]
    end

    def campfire_message(app_name, messages)
      msg = [
        '<message>',
          '<type>TextMessage</type>',
          "<body>%s has %d Alerts:\n%s</body>" % [ app_name, messages.count, messages.join("\n") ],
        '</message>'
      ].join
    end
  end
end
