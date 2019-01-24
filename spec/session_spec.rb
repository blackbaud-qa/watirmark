require_relative 'spec_helper'

describe Watirmark::Session do
  before :all do
    @html = File.expand_path(File.dirname(__FILE__) + '/html/controller.html')
    @config = Watirmark::Configuration.instance
  end

  before :each do
#    Watirmark::Session.instance.closebrowser
    @config.reload
  end

  specify "check firefox to close the browser" do
    session = Watirmark::Session.instance
    b = session.openbrowser
    b.goto "file://#{@html}"
    session.closebrowser
    expect(b.instance_variable_get('@closed')).to eq(true)
  end

  specify 'does not run headless when headless set to false' do
    @config.headless = false
    session = Watirmark::Session.instance
    b = session.openbrowser
    b.goto "file://#{@html}"
    expect(b.title == "Controller Page").to be true
    expect(b.instance_variable_get('@closed')).to eq(false)
    expect(session.instance_variable_get('@headless')).to be_nil
  end

  # CI can not use chrome; must verify locally
  context "when running with Chrome" do
    xit "check chrome to close the browser" do
      @config.webdriver = 'chrome'
      session = Watirmark::Session.instance
      b = session.newsession
      b.goto "file://#{@html}"
      session.closebrowser
      expect(b.instance_variable_get('@closed')).to eq(true)
    end

    # Have to use chrome; headless doesn't always play well with Firefox
    xit 'can run headless on linux' do
      @config.webdriver = 'chrome'
      @config.headless = true
      session = Watirmark::Session.instance
      b = session.openbrowser
      b.goto "file://#{@html}"
      expect(b.title).to eq("Controller Page")
      expect(b.instance_variable_get('@closed')).to eq(false)
      expect(session.instance_variable_get('@headless')).not_to be_nil
    end
  end

end