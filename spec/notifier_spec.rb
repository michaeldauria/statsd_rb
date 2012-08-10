require File.join(File.dirname(__FILE__), 'spec_helper')

describe Statsd::Notifier do
  before do
    config = Statsd::Runner.default_config.merge({
      'rules' => {
        "stats.timers.important.mean" => { 'threshold' => { 'min' => 5, 'max' => 10 } },
        "stats.timers.very_important.mean" => { 'threshold' => { 'min' => 1, 'max' => 5 } },
        "stats.timers.period_check.mean" => { 'threshold' => { 'min' => 1, 'max' => 5, 'period' => 20 } }
      }
    })
    @server = Statsd::Server.new('signature', config)
  end

  it "matches if the stat is below the threshold" do
    @server.receive_data('important:0|ms')
    @server.notify!(@server.aggregate!).should == 1
  end

  it "matches if the stat is greater than the threshold" do
    @server.receive_data('important:50|ms')
    @server.notify!(@server.aggregate!).should == 1
  end

  it "does not match if the stat is within the threshold" do
    @server.receive_data('important:7|ms')
    @server.notify!(@server.aggregate!).should == 0
  end

  it "matches all stats over the threshold" do
    @server.receive_data('important:50|ms')
    @server.receive_data('very_important:50|ms')
    @server.notify!(@server.aggregate!).should == 2
  end

  it "matches all stats over the threshold & period" do
    @server.receive_data('period_check:50|ms')
    @server.notify!(@server.aggregate!).should == 0
    @server.notify!(@server.aggregate!).should == 1
    @server.notify!(@server.aggregate!).should == 0
  end
end

describe 'Statsd::Notifier.alert_messages' do
  before do
    @server = Statsd::Server.new('signature', {})
  end

  it "has an appropriate alert message" do
    matched = [
      [ "stats.timers.important.mean", 50, { 'threshold' => { 'min' => 5, 'max' => 10 } }, { 'over_max' => true, 'under_min' => true } ],
      [ "stats.timers.period_check.mean", 0, { 'threshold' => { 'min' => 1, 'max' => 5, 'period' => 20 } }, { 'over_max' => false, 'under_min' => true } ]
    ]

    @server.alert_messages(matched).should == ["stats.timers.important.mean: [50] is over the threshold of 10", "stats.timers.period_check.mean: [0] is under the threshold of 1 for 20s"]
  end
end
