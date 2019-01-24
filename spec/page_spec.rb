require_relative 'spec_helper'

describe 'Page' do

  before :all do
    class Page1 < Page
      keyword(:a) { "a" }
      keyword(:b) { "b" }
    end
    class Page2 < Page
      keyword(:c) { "c" }
    end
    class Page3 < Page
      populate_keyword(:d) { "d" }
      verify_keyword(:e) { "e" }
    end
    class Page4 < Page
      navigation_keyword(:f) { "f" }
      private_keyword(:g) { "g" }
      keyword(:h) { "h" }
    end
    class Page5 < Page1
      keyword(:i) { "i" }
    end
    class Page6 < Page

    end

    @page1 = Page1.new
    @page2 = Page2.new
    @page3 = Page3.new
    @page4 = Page4.new
    @page5 = Page5.new
    @page6 = Page6.new
  end

  it "should handle empty keywords gracefully" do
    expect(@page6.keywords).to eq([])
  end

  it "should list its keywords" do
    expect(@page1.keywords).to eq([:a, :b])
    expect(@page2.keywords).to eq([:c])
  end

  it "should list its parent's keywords" do
    expect(@page5.keywords).to eq([:a, :b, :i])
  end


  it "should list its own keywords" do
    expect(@page5.native_keywords).to eq([:i])
  end


  it "should list populate and verify keywords" do
    expect(@page3.keywords).to eq([:d, :e])
  end

  it 'should create a method for the keyword' do
    expect(@page1.a).to eq('a')
    expect(@page2.c).to eq('c')
    expect(@page4.h).to eq('h')
  end

  it 'should be able to get and set the browser' do
    old_browser = Page.browser
    begin
      Page.browser = 'browser'
      expect(Page1.new.browser).to eq('browser')
      expect(Page2.new.browser).to eq('browser')
      expect(Page3.new.browser).to eq('browser')
      expect(Page4.new.browser).to eq('browser')
    ensure
      Page.browser = old_browser
    end
  end

  it 'should not leak keywords to other classes' do
    expect(lambda { @page2.a }).to raise_error
    expect(lambda { @page1.c }).to raise_error
  end

  it 'should support aliasing keywords' do
    class Page1 < Page
      keyword_alias :aliased_keyword, :a
    end
    page1 = Page1.new
    expect(page1.a).to eq('a')
    expect(page1.aliased_keyword).to eq('a')
  end
end

describe "keyword metadata inheritance" do

  before :all do
    class Parent < Page
      keyword(:a) { "a" }
      keyword(:b) { "b" }
      keyword(:same) { "c1" }
    end

    class Child < Parent
      keyword(:c) { "c" }
      keyword(:same) { "c1-child" }
    end

    class Child2 < Parent
      keyword(:g) { "g" }
    end
  end

  it 'should get declared keywords' do
    parent = Parent.new
    expect(parent.keywords).to eq([:a, :b, :same])
  end

  it 'should allow child to override superclass' do
    child = Child.new
    expect(child.keywords.sort_by { |k| k.to_s }).to eq([:a, :b, :c, :same])
    expect(child.a).to eq("a")
    expect(child.same).to eq('c1-child')
  end

  it 'should not bleed settings between children' do
    child2 = Child2.new
    expect(child2.keywords.sort_by { |k| k.to_s }).to eq([:a, :b, :g, :same])
    expect(child2.g).to eq('g')
    expect(child2.same).to eq('c1')
  end
end




