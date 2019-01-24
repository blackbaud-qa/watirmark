require_relative 'spec_helper'

describe "ModelOpenStruct includes?" do
  before :all do
    @struct = ModelOpenStruct.new(a: 1, b: 2, c: 'three')
  end

  it 'open struct includes hash' do
    expect(@struct.includes?(a: 1, c: 'three')).to eq(true)
  end

  it 'open struct does not include hash' do
    expect(@struct.includes?(d: 1)).to eq(false)
  end

  it 'single element hash' do
    expect(@struct.includes?(a: 1)).to eq(true)
  end

  it 'return true if hash is nil' do
    expect { @struct.includes?(nil) }.to raise_error
  end

  it 'throw error if hash is not passed' do
    expect { @struct.includes?(Object.new) }.to raise_error
  end
end
