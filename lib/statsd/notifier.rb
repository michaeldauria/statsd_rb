module Statsd
  module Notifier
    attr_reader :notifiers

    def notify!(stat_string)
      matched = []
      stat_string.each_line do |line|
        stat, value, ts = line.split(' ')

        if rule = @config['rules'][stat]
          if stat_check = check_stat(stat, value, rule)
            threshold_period = rule['threshold']['period']
            if threshold_period
              @period[stat] ||= reset_stat_period(stat)
              @period[stat] += 1

              if @period[stat] == (threshold_period / @config['flush_interval'])
                matched << [stat, value, rule, stat_check]
                @period[stat] = reset_stat_period(stat)
              end
            else
              matched << [stat, value, rule, stat_check]
            end
          elsif threshold_period
            @period[stat] = reset_stat_period(stat)
          end
        end
      end

      send_notifications!(alert_messages(matched)) unless matched.empty?

      matched.count
    end

    def alert_messages(matched)
      alert_msgs = []
      matched.each do |stat, value, rule, check|
        msg = [
          '%s: [%s]' % [stat, value]
        ]

        if check['over_max']
          msg << 'is over the threshold of %s' % rule['threshold']['max']
        else
          msg << 'is under the threshold of %s' % rule['threshold']['min']
        end

        if rule['threshold']['period']
          msg << 'for %ss' % rule['threshold']['period']
        end

        alert_msgs << msg.join(' ')
      end

      alert_msgs
    end

    def check_stat(stat, value, rule)
      threshold_max = rule['threshold']['max']
      threshold_min = rule['threshold']['min']

      value = value.to_f
      over_max = (threshold_max && value > threshold_max.to_f)
      under_min = (threshold_min && value < threshold_min.to_f)

      if (over_max || under_min)
        { 'over_max' => over_max, 'under_min' => under_min }
      else
        false
      end
    end

    def register_notifiers
      @notifiers = []
      if @config['notifications']
        if @config['notifications']['campfire']
          @notifiers << Notifier::Campfire.new(@config['app_name'], @config['notifications']['campfire'])
        end

        if @config['notifications']['email']
          @notifiers << Notifier::Email.new(@config['app_name'], @config['notifications']['email'])
        end
      end
    end

    private

    def reset_stat_period(stat)
      @period[stat] = 0
    end

    def send_notifications!(messages)
      @notifiers.each { |notifier| notifier.send!(messages) }
    end
  end
end
