module Statsd
  class Notifier::Email
    def initialize(app_name, config)
      @app_name = app_name
      @config = {
        domain:   'localhost',
        host:     'localhost',
        port:     25,
        starttls: false,
        from:     'statsd alerts',
        to:       []
      }.merge!(config)
    end

    def send!(messages)
      opts = @config.merge({
        header: { 'Subject' => subject(messages) },
        body:   messages.join("\n")
      })
      email = EM::Protocols::SmtpClient.send(opts)

      email.callback do
        puts 'Email sent!'
      end

      email.errback do |e|
        puts 'Email failed!'
      end
    end

    private

    def subject(messages)
      '[%s] %d Alert%s' % [ @app_name, messages.count, (messages.count == 1)? '':'s' ]
    end
  end
end
