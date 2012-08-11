module Statsd
  class Notifier::Email
    def initialize(app_name, config)
      @app_name = app_name

      @config = {
        :domain   => config['domain']   || 'localhost',
        :host     => config['host']     || 'localhost',
        :port     => config['port']     || 25,
        :starttls => config['starttls'] || false,
        :from     => config['from']     || 'statsd alerts',
        :to       => config['to']       || []
      }

      if config['auth']
        @config[:auth] = {}
        @config[:auth][:type]     = config['auth']['type']
        @config[:auth][:username] = config['auth']['username']
        @config[:auth][:password] = config['auth']['password']
      end
    end

    def send!(messages)
      opts = @config.merge({
        'header' => { 'Subject' => subject(messages) },
        'body'   => messages.join("\n")
      })
      email = EM::Protocols::SmtpClient.send(opts)

      email.errback do |e|
        puts 'Email failed!'
        puts e.to_yaml
      end
    end

    private

    def subject(messages)
      '[%s] %d Alert%s' % [ @app_name, messages.count, (messages.count == 1)? '':'s' ]
    end
  end
end
