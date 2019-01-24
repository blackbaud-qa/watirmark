require_relative 'spec_helper'

describe Watirmark::Assertions do
  include Watirmark::Assertions
  
  it 'can compare simple elements' do
    element = stub(:exists? => true, :value => 'giant vampire squid', :radio_map => nil)
    assert_equal element, 'giant vampire squid'
  end
  
  it 'compare integer' do
    element = stub(:exists? => true, :value => '100')
    assert_equal element, 100
  end

  it 'compare string integer' do
    element = stub(:exists? => true, :value => '100')
    assert_equal element, '100'
  end

  it 'expecting value with with percent' do
    element = stub(:exists? => true, :value => '100%')
    assert_equal element, '100%'
  end

  it 'expecting value with with a currency symbol' do
    element = stub(:exists? => true, :value => '$123.45')
    assert_equal element, '$123.45'
  end

  it 'expecting integer value should strip the dollar sign' do
    element = stub(:exists? => true, :value => '$25')
    assert_equal element, '25'
    assert_equal element, '$25'
    expect(lambda { assert_equal element, '25%' }).to raise_error
  end

  it 'symbol in wrong place needs to match exactly or fail' do
    element = stub(:exists? => true, :value => '25$')
    expect(lambda { assert_equal element, '$25' }).to raise_error
    assert_equal element, '25$'

    element = stub(:exists? => true, :value => '%50')
    expect(lambda { assert_equal element, '50%' }).to raise_error
    expect(lambda { assert_equal element, '50' }).to raise_error
    assert_equal element, '%50'
  end

  it 'should detect two different numbers are different' do
    element = stub(:exists? => true, :value => '50')
    expect(lambda { assert_equal element, '51' }).to raise_error
    expect(lambda { assert_equal element, '50.1' }).to raise_error
    expect(lambda { assert_equal element, 49.9 }).to raise_error
    expect(lambda { assert_equal element, 49 }).to raise_error
    assert_equal element, 50.0
  end

  it 'should let a number match a number with a $ before or % after' do
    element = stub(:exists? => true, :value => '$26', :name => 'unittest')
    assert_equal element, 26
    element = stub(:exists? => true, :value => '27%', :name => 'unittest')
    assert_equal element, 27.00
  end

  it 'should let a number in a string match a number with currency or percent' do
    element = stub(:exists? => true, :value => '$36', :name => 'unittest')
    assert_equal element, '36'
    element = stub(:exists? => true, :value => '37%', :name => 'unittest')
    assert_equal element, '37.00'
  end
end

describe "normalize_values" do
  include Watirmark::Assertions

  specify 'normalize dates' do
    expect(normalize_value("1/1/2012")).to eq(Date.parse('1/1/2012'))
    expect(normalize_value("1/1/09")).to eq(Date.parse('1/1/09'))
    expect(normalize_value("01/1/09")).to eq(Date.parse('1/1/09'))
    expect(normalize_value("01/01/09")).to eq(Date.parse('1/1/09'))
  end
  specify 'normalize whitespace' do
    expect(normalize_value(" a")).to eq("a")
    expect(normalize_value("a ")).to eq("a")
    expect(normalize_value("a\n")).to eq("a")
    expect(normalize_value("\na")).to eq("a")
    expect(normalize_value(" a \nb")).to eq("a \nb")
    expect(normalize_value(" a \r\nb")).to eq("a \nb")
    expect(normalize_value(" a \nb\n")).to eq("a \nb")
  end
  specify 'do not normalize string of spaces' do
    expect(normalize_value('     ')).to eq('     ')
  end
end
