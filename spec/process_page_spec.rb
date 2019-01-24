require_relative 'spec_helper'

describe 'ProcessPage' do

  it 'should implement a process page interface' do
    expect(lambda{Watirmark::ProcessPage.new('pp')}).not_to raise_error
  end

  it 'should support an activate method' do
    p = Watirmark::ProcessPage.new('pp')
    expect(lambda{p.activate}).not_to raise_error
  end

end

describe 'Process Page Views' do

  before :all do
    class ProcessPageTest < Watirmark::Page
      keyword(:a) {'a'}
      process_page('ProcessPage 1') do
        keyword(:b) {'b'}
      end
      process_page('ProcessPage 2') do
        keyword(:c) {'c'}
        keyword(:d) {'d'}
      end
      keyword(:e) {'e'}
    end

    class NestedProcessPageTest < Watirmark::Page
      keyword(:a) {'a'}
      process_page('ProcessPage 1') do
        keyword(:b) {'b'}
        process_page('ProcessPage 1.1') do
          keyword(:b1) {'b1'}
          keyword(:b2) {'b2'}
          process_page('ProcessPage 1.1.1') do
            keyword(:b3) {'b3'}
          end
        end
      end
      keyword(:c) {'c'}
    end

    class DefaultView < Watirmark::Page
      keyword(:a) {'a'}
      keyword(:b) {'b'}
    end

    class ProcessPageView < Watirmark::Page
      process_page 'page 1' do
        keyword(:a) {'a'}
      end
      process_page 'page 2' do
        keyword(:b) {'b'}
      end
    end

    class ProcessPageAliasView < Watirmark::Page
      process_page 'page 1' do
        process_page_alias 'page a'
        process_page_alias 'page b'
        keyword(:a) {'a'}
      end
      process_page 'page 2' do
        keyword(:b) {'b'}
      end
    end

    class ProcessPageSubclassView < ProcessPageView
      process_page 'page 3' do
        keyword(:c) {'c'}
      end
    end

    class ProcessPageCustomNav < Watirmark::Page
      process_page_navigate_method Proc.new {}
      process_page_submit_method Proc.new {}
      process_page_active_page_method Proc.new {}
      process_page 'page 4' do
        keyword(:d) {'d'}
      end
    end

    @processpagetest = ProcessPageTest.new
    @nestedprocesspagetest = NestedProcessPageTest.new
    @processpage = ProcessPageView.new
    @processpagealias = ProcessPageAliasView.new
    @processpagesubclass = ProcessPageSubclassView.new
    @processpagecustomnav = ProcessPageCustomNav.new
  end

  it 'should only activate process_page when in the closure' do
    expect(@processpagetest.a).to eq('a')
    expect(@processpagetest.b).to eq('b')
    expect(@processpagetest.c).to eq('c')
    expect(@processpagetest.d).to eq('d')
    expect(@processpagetest.e).to eq('e')
    expect(@processpagetest.keywords).to eq([:a,:b,:c,:d,:e])
  end

  it 'should show all keywords for a given process page' do
    expect(@processpagetest.process_page('ProcessPage 1').keywords).to eq([:b])
    expect(@processpagetest.process_page('ProcessPage 2').keywords).to eq([:c, :d])
  end

  it 'should activate the nested process_page where appropriate' do
    expect(@nestedprocesspagetest.a).to eq('a')
    expect(@nestedprocesspagetest.b).to eq('b')
    expect(@nestedprocesspagetest.b1).to eq('b1')
    expect(@nestedprocesspagetest.b2).to eq('b2')
    expect(@nestedprocesspagetest.b3).to eq('b3')
    expect(@nestedprocesspagetest.c).to eq('c')
  end

  it 'should support defining the process page navigate method' do
    custom_method_called = false
    Watirmark::ProcessPage.navigate_method_default = Proc.new { custom_method_called = true }
    expect(@processpagetest.a).to eq('a')
    expect(custom_method_called).to eq(false)
    expect(@processpagetest.b).to eq('b')
    expect(custom_method_called).to eq(true)
  end

  it 'should support defining the process page submit method' do
    process_page = @processpagealias.process_page('page 1')
    expect(process_page.alias).to eq(['page a', 'page b'])
  end

  it 'should be able to report all process pages' do
    expect(@processpage.process_pages[0].name).to eq('')
    expect(@processpage.process_pages[1].name).to eq('page 1')
    expect(@processpage.process_pages[2].name).to eq('page 2')
    expect(@processpage.process_pages.size).to eq(3)
  end

  it 'should include process page keywords in subclasses' do
    expect(@processpagesubclass.process_pages[0].name).to eq('')
    expect(@processpagesubclass.process_pages[1].name).to eq('page 1')
    expect(@processpagesubclass.process_pages[2].name).to eq('page 2')
    expect(@processpagesubclass.process_pages[3].name).to eq('')
    expect(@processpagesubclass.process_pages[4].name).to eq('page 3')
    expect(@processpagesubclass.process_pages.size).to eq(5)
    expect(@processpagesubclass.keywords).to eq([:a, :b, :c])
  end

  it 'should honor overriding default process page behavior' do
    expect(@processpagesubclass.c).to eq('c')
    expect(@processpagesubclass.class.instance_variable_get(:@process_page_active_page_method)).not_to be_kind_of(Proc)
    expect(@processpagesubclass.class.instance_variable_get(:@process_page_navigate_method)).not_to be_kind_of(Proc)
    expect(@processpagesubclass.class.instance_variable_get(:@process_page_submit_method)).not_to be_kind_of(Proc)

    expect(@processpagecustomnav.d).to eq('d')
    expect(@processpagecustomnav.class.instance_variable_get(:@process_page_active_page_method)).to be_kind_of(Proc)
    expect(@processpagecustomnav.class.instance_variable_get(:@process_page_navigate_method)).to be_kind_of(Proc)
    expect(@processpagecustomnav.class.instance_variable_get(:@process_page_submit_method)).to be_kind_of(Proc)
  end
end




