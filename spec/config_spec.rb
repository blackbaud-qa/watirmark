require_relative 'spec_helper'

describe "text file" do

  before :all do
    @config = Watirmark::Configuration.instance
    @config.reset
    @config.configfile = File.dirname(__FILE__) + '/configurations/config.txt'
    @config.read_from_file
  end

 specify 'string' do
   expect(@config.string).to eq("foo")
 end

 specify 'true_boolean' do
   expect(@config.true_boolean).to eq(true)
 end

 specify 'false_boolean' do
   expect(@config.false_boolean).to eq(false)
 end

 specify 'symbol' do
   expect(@config.symbol).to eq(:foo)
 end

 specify 'integer' do
   expect(@config.integer).to eq(3)
 end

 specify 'float' do
   expect(@config.float).to eq(1.2)
 end
end

describe "yaml file" do

  before :all do
    @config = Watirmark::Configuration.instance
    @config.reset
    @config.configfile = File.dirname(__FILE__) + '/configurations/config.yml'
    @config.read_from_file
  end

  specify 'string' do
    expect(@config.string).to eq("foo")
  end

  specify 'true_boolean' do
    expect(@config.true_boolean).to eq(true)
  end

  specify 'false_boolean' do
    expect(@config.false_boolean).to eq(false)
  end

  specify 'symbol' do
    expect(@config.symbol).to eq(:foo)
  end

  specify 'integer' do
    expect(@config.integer).to eq(3)
  end

  specify 'float' do
    expect(@config.float).to eq(1.2)
  end
end

describe "configuration" do
  before :all do
    @config = Watirmark::Configuration.instance
    @config.reset
    @config.reload
  end

  specify 'add defaults' do
    expect(@config.email).to eq('devnull')
    expect(@config.webdriver).to eq('firefox')
    @config.defaults = {:email => 'email-changed'}
    expect(@config.email).to eq('email-changed')
    expect(@config.webdriver).to eq('firefox')
  end

  specify 'inspect' do
    expect(@config.inspect).to match(/^{.+}/)
  end

end
