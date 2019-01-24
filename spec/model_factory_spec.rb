# encoding: UTF-8
require_relative 'spec_helper'

describe "factory" do
  before :all do
    module FactoryTest
      class InitializeModel < Watirmark::Model::Factory
        keywords :username, :password
      end

      class UniqueDefaultsModel < Watirmark::Model::Factory
        keywords :test_name
        defaults do
          test_name { unique_instance_name }
        end
      end

    end
  end

  specify "set a value on instantiation" do
    login = FactoryTest::InitializeModel.new(:username => 'username', :password => 'password')
    expect(login.username).to eq('username')
    expect(login.password).to eq('password')
  end

  specify "set a value after initialized" do
    login = FactoryTest::InitializeModel.new
    expect(login.username).to be_nil
    expect(login.password).to be_nil
    login.username = 'username'
    login.password = 'password'
    expect(login.username).to eq('username')
    expect(login.password).to eq('password')
  end

  # this is mostly for legacy :(
  specify "should be able to act like an openstruct" do
    login = FactoryTest::InitializeModel.new
    expect(login.foobar).to be_nil
    login.foobar = 'test'
    expect(login.foobar).to eq('test')
  end

  specify 'to_h' do
    login = FactoryTest::InitializeModel.new(username: 'foo', password: 'bar')
    expect(login.to_h).to eq({:username=>"foo", :password=>"bar"})
  end

  specify "should generate custom unique_instance_name given model_name" do
    demo_model = FactoryTest::UniqueDefaultsModel.new({:model_name => "RspecUniqueName"})
    expect(demo_model.test_name).to match(/^RspecUniqueName_[\dA-Za-z]+$/)
  end

  specify "should generate default unique_instance_name given no model_name" do
    demo_model = FactoryTest::UniqueDefaultsModel.new()
    expect(demo_model.test_name).to match(/^uniquedefaults_[\dA-Za-z]+$/)
  end
end

describe "#update" do
  before :all do
    module FactoryTest
      class UpdateModel < Watirmark::Model::Factory
        keywords :username, :password
      end
    end
  end

  specify "model update should create methods if not in model" do
    login = FactoryTest::UpdateModel.new
    login.update(:foobar=>1)
    expect(login.foobar).to eq(1)
    login.foobar = 'test'
    expect(login.foobar).to eq('test')
  end

  specify "keywords should not bleed across instances for defined methods" do
    first = FactoryTest::UpdateModel.new
    first.username = 'username'
    expect(first.username).to eq('username')
    second = FactoryTest::UpdateModel.new
    expect(second.username).to be_nil
  end

  specify "keywords should not bleed across instances for auto-created methods" do
    first = FactoryTest::UpdateModel.new
    first.update(:foobar=>1)
    second = FactoryTest::UpdateModel.new
    expect(second.respond_to?(:foobar)).to eq(false)
    expect(second.respond_to?(:foobar)).to eq(false)
  end

  specify "model update should remove empty keys" do
    keys = FactoryTest::UpdateModel.new
    expect(lambda{keys.update(':'=>'') }).not_to raise_error
    expect(lambda{keys.update(nil=>'') }).not_to raise_error
    expect(lambda{keys.update('   '=>'') }).not_to raise_error
    expect(lambda{keys.update('   '.to_sym=>'') }).not_to raise_error
  end

end

describe "defaults" do
  before :all do
    module FactoryTest
      class DefaultModel < Watirmark::Model::Factory
        keywords :first_name, :last_name, :middle_name, :nickname, :id, :desc
        defaults do
          first_name { 'my_first_name' }
          last_name { 'my_last_name' }
          middle_name { "#{model_name} middle_name".strip }
          id { uuid }
          desc { 'some description' }
        end
      end
    end
  end

  specify "retrieve a default proc setting" do
    m = FactoryTest::DefaultModel.new
    expect(m.middle_name).to eq('middle_name')
    m.model_name = 'foo'
    expect(m.middle_name).to eq('foo middle_name')
  end

  specify "update a default setting" do
    m = FactoryTest::DefaultModel.new
    expect(m.first_name).to eq('my_first_name')
    m.first_name = 'fred'
    expect(m.first_name).to eq('fred')
  end

  specify "retrieve a default setting" do
    expect(FactoryTest::DefaultModel.new.first_name).to eq('my_first_name')

  end

  specify "workaround for desc as a default when run from rake" do
    expect(FactoryTest::DefaultModel.new.desc).to eq('some description')
  end

  specify "override default settings on instantiation" do
    module FactoryTest
      class ModelWithDefaults < Watirmark::Model::Factory
        keywords :foo, :bar
        defaults do
          foo { "hello from proc" }
        end
      end
    end

    m = FactoryTest::ModelWithDefaults.new :foo => 'hello init'
    expect(m.foo).to eq('hello init')
  end

  # specify "defaults can reference each other" do
  #   module FactoryTest
  #     class DefaultReference < Watirmark::Model::Factory
  #       keywords :name, :sort_name
  #       defaults do
  #         name { "name" }
  #         sort_name { name }
  #       end
  #     end
  #
  #     model = DefaultReference.new
  #     expect(model.name).to eq('name')
  #     expect(model.sort_name).to eq('name')
  #   end
  # end

  specify "should raise error unless a proc is defined" do
    expect(lambda {
      module FactoryTest
        class Test < Watirmark::Model::Factory
          keywords :first_name, :last_name, :middle_name, :nickname, :id
          defaults do
            first_name 'my_first_name'
          end
        end
      end
      FactoryTest::Test.new
    }).to raise_error ArgumentError
  end
end

describe "model name" do
  before :all do
    class ModelName < Watirmark::Model::Factory
      keywords :middle_name
      defaults do
        middle_name { "#@model_name middle_name".strip }
      end
    end
  end

  specify "can set the models name" do
    m = ModelName.new
    m.model_name = 'my_model'
    expect(m.model_name).to eq('my_model')
  end

  specify "can set the models at initialize (used by transforms)" do
    m = ModelName.new(:model_name => 'my_model')
    expect(m.model_name).to eq('my_model')
  end

  specify "setting the models name changes the defaults" do
    m = ModelName.new
    m.model_name = 'my_model'
    expect(m.middle_name).to match(/^my_model/)
  end
end


describe "parents" do
  specify "ask for a parent" do
    module FactoryTest
      class ChildModel < Watirmark::Model::Factory
        keywords :name, :value
        defaults do
          name { parent.name }
        end
      end

      class ParentModel < Watirmark::Model::Factory
        keywords :name
        model ChildModel
        defaults do
          name { 'a' }
        end
      end
    end
    model = FactoryTest::ParentModel.new
    expect(model.child.parent).to eq(model)
    expect(model.child.parent.name).to eq('a')
    expect(model.child.name).to eq('a')
  end
end

describe "children" do
  before :all do
    module FactoryTest
      class Camelize < Watirmark::Model::Factory
        keywords :first_name, :last_name
      end

      class Login < Watirmark::Model::Factory
        keywords :username, :password
        defaults do
          username { 'username' }
          password { 'password' }
        end
      end

      class User < Watirmark::Model::Factory
        keywords :first_name, :last_name
        model Login, Camelize
        defaults do
          first_name { 'my_first_name' }
          last_name { 'my_last_name' }
        end
      end

      class Donor < Watirmark::Model::Factory
        keywords :credit_card
        model User
      end

      class SDP < Watirmark::Model::Factory
        keywords :name, :value
      end

      class Config < Watirmark::Model::Factory
        keywords :name
      end
    end

  end

  specify "should be able to see the models" do
    model = FactoryTest::User.new
    expect(model.login.username).to eq('username')
  end

  specify "should be able to see nested models" do
    model = FactoryTest::Donor.new
    expect(model.user.login.username).to eq('username')
    expect(model.users.first.login.username).to eq('username')
  end

  specify "multiple models of the same class should form a collection" do
    model = FactoryTest::Config.new
    model.add_model FactoryTest::SDP.new(:name => 'a', :value => 1)
    model.add_model FactoryTest::SDP.new(:name => 'b', :value => 2)
    expect(model.sdp.name).to eq('a')
    expect(model.sdps.size).to eq(2)
    expect(model.sdps.first.name).to eq('a')
    expect(model.sdps.last.name).to eq('b')
  end

  specify "should raise an exception if the model is not a constant" do
    expect(lambda {
      class Test < Watirmark::Model::Factory
        keywords :name
        model :FactorySDP.new
      end
    }).to raise_error
  end

  specify "should always instantiate NEW instances of sub-models" do
    module FactoryTest
      class Item < Watirmark::Model::Factory
        keywords :name, :sort_name
        defaults do
          name { "name" }
        end
      end
      class Container < Watirmark::Model::Factory
        keywords :name, :sort_name
        search_term { name }
        model Item
      end
    end
    c = FactoryTest::Container.new
    expect(c.item.name).to eq('name')
    c.item.name = 'foo'
    expect(c.item.name).to eq('foo')
    d = FactoryTest::Container.new
    expect(d.item.name).not_to eq('foo')
  end

  specify "models containing models in modules should not break model_class_name" do
    module Foo
      module Bar
        class Login < Watirmark::Model::Factory
          keywords :username, :password
          defaults do
            username { 'username' }
            password { 'password' }
          end
        end

        class User < Watirmark::Model::Factory
          keywords :first_name, :last_name
          model Login
          defaults do
            first_name { 'my_first_name' }
            last_name { 'my_last_name' }
          end
        end
      end
    end

    model = Foo::Bar::User.new
    expect(model.login.username).to eq('username')
  end
end

describe "search_term" do
  specify "is a string" do
    module FactoryTest
      class SearchIsString < Watirmark::Model::Factory
        keywords :name, :sort_name
        search_term { "name" }
        defaults do
          name { "name" }
        end
      end
    end
    model = FactoryTest::SearchIsString.new
    expect(model.search_term).to eq('name')
  end

  specify "matches another default" do
    module FactoryTest
      class SearchIsDefault < Watirmark::Model::Factory
        keywords :name, :sort_name
        search_term { name }
        defaults do
          name { "name" }
        end
      end
    end
    model = FactoryTest::SearchIsDefault.new
    expect(model.search_term).to eq('name')
  end

  specify "is found in a parent" do
    module FactoryTest
      class SearchChild < Watirmark::Model::Factory
        keywords :name, :sort_name
      end

      class SearchParent < Watirmark::Model::Factory
        keywords :name, :sort_name
        search_term { name }
        model SearchChild
        defaults do
          name { "name" }
        end
      end
    end
    child = FactoryTest::SearchChild.new
    expect(child.search_term).to be_nil
    parent = FactoryTest::SearchParent.new
    expect(parent.search_term).to eq('name')
    expect(parent.search_child.search_term).to eq('name')
  end
end

describe "find" do
  before :all do
    module FactoryTest
      class FirstModel < Watirmark::Model::Factory
        keywords :x
      end
      class SecondModel < Watirmark::Model::Factory
        keywords :x
      end
      class NoAddedModels < Watirmark::Model::Factory
        keywords :x
      end
      class SingleModel < Watirmark::Model::Factory
        keywords :x
      end
      class MultipleModels < Watirmark::Model::Factory
        keywords :x
      end
    end


    @first_model = FactoryTest::FirstModel.new
    @second_model = FactoryTest::SecondModel.new
    @no_added_models = FactoryTest::NoAddedModels.new
    @single_model = FactoryTest::SingleModel.new
    @single_model.add_model @first_model
    @multiple_models = FactoryTest::MultipleModels.new
    @multiple_models.add_model @first_model
    @multiple_models.add_model @second_model
  end

  specify 'should find itself' do
    expect(@no_added_models.find(FactoryTest::NoAddedModels)).to eq(@no_added_models)
    expect(@single_model.find(FactoryTest::SingleModel)).to eq(@single_model)
    expect(@multiple_models.find(FactoryTest::MultipleModels)).to eq(@multiple_models)
  end

  specify 'should be able to see a sub_model' do
    expect(@single_model.find(FactoryTest::FirstModel)).to eq(@first_model)
    expect(@multiple_models.find(FactoryTest::FirstModel)).to eq(@first_model)
    expect(@multiple_models.find(FactoryTest::SecondModel)).to eq(@second_model)
  end

  specify 'should be return nil when no model is found' do
    expect(@no_added_models.find(FactoryTest::FirstModel)).to be_nil
    expect(@single_model.find(FactoryTest::NoAddedModels)).to be_nil
    expect(@multiple_models.find(FactoryTest::NoAddedModels)).to be_nil
  end
end

describe "methods in Enumerable should not collide with model defaults" do
  it "#zip" do
    module FactoryTest
      class ZipModel < Watirmark::Model::Factory
        keywords :zip
        defaults do
          zip { 78732 }
        end
      end
    end
    expect(FactoryTest::ZipModel.new.zip).to eq(78732)
  end

  it "#zip not in model" do
    module FactoryTest
      class NoZipModel < Watirmark::Model::Factory
        keywords :foo
        defaults do
        end
      end
    end
    expect(FactoryTest::NoZipModel.new.respond_to?(:zip)).not_to eq(true)
  end

end

describe "keywords" do
  before :all do
    module FactoryTest
      class Element
        attr_accessor :value

        def initialize(x)
          @value = x
        end
      end

      class SomeView < Page
        keyword(:first_name)  { Element.new :a }
        keyword(:middle_name) { Element.new :b }
        keyword(:last_name)   { Element.new :c }
      end

      class SomeModel < Watirmark::Model::Factory
        keywords SomeView.keywords
        defaults do
          first_name { "First" }
          middle_name { "Middle" }
          last_name { "Last #{uuid}" }
        end
      end

      class SomeOtherModel < Watirmark::Model::Factory
        keywords SomeView.keywords
        defaults do
          first_name { "First" }
          middle_name { "Middle" }
          last_name { "Last #{uuid}" }
        end
      end

      class MultipleKeywordsModel < Watirmark::Model::Factory
        keywords :first_name
        keywords :last_name
        defaults do
          first_name { "First" }
          last_name {"Last"}
        end
      end

      class DuplicateKeywordsModel < Watirmark::Model::Factory
        keywords :first_name, :first_name
        defaults do
          first_name { "First" }
        end
      end
    end
  end

  specify "should add unpacked keywords as keywords" do
    a = FactoryTest::SomeModel.new
    expect(a.middle_name).to eq("Middle")
    expect(a.first_name).to eq("First")
    expect(a.last_name).to include("Last")
  end

  specify "keywords can be specified without the asterisk" do
    a = FactoryTest::SomeOtherModel.new
    expect(a.middle_name).to eq("Middle")
    expect(a.first_name).to eq("First")
    expect(a.last_name).to include("Last")
  end

  specify "should be able to list keywords for a model" do
    expect(FactoryTest::SomeModel.new.keywords.sort).to eq([:first_name, :middle_name, :last_name].sort);
  end

  specify "should be able to support multiple calls to keywords method" do
    a = FactoryTest::MultipleKeywordsModel.new
    expect(a.first_name).to eq("First")
    expect(a.keywords.include?(:last_name)).to eq(true)
    expect(a.last_name).to eq("Last")
  end

  specify "should not contain duplicate values in the keywords" do
    a = FactoryTest::DuplicateKeywordsModel.new
    expect(a.keywords.size).to eq(1)
  end

end

describe "subclassing" do
  before :all do
    module Watirmark::Model
      trait :some_trait do
        full_name { "full_name" }
      end

      trait :new_trait do
        dog_name {"sugar"}
      end
    end
    module FactoryTest
      class BaseModel < Watirmark::Model::Factory
        keywords :first_name, :last_name, :full_name, :attr_test, :base_attr
        defaults do
          first_name { 'base_first_name' }
          last_name { 'base_last_name' }
          attr_test { 'I came from BaseModel' }
          base_attr { 'This is a base attribute' }
        end
        traits :some_trait
      end

      class SubModel < BaseModel
        defaults do
          first_name { 'sub_first_name' }
          last_name { 'sub_last_name' }
          attr_test { 'I came from SubModel'}
        end
      end

      class NoDefaultModel < BaseModel
      end

      class KeywordsSubModel < BaseModel
        keywords :middle_name, :cat_name, :dog_name
        traits :new_trait
        defaults do
          middle_name {'middle_name'}
          cat_name {'Annie'}
        end
      end

      class DuplicateKeywordsSubModel < BaseModel
        keywords :first_name
      end
    end
  end

  specify "submodel should be able to inherit keywords" do
    expect(FactoryTest::SubModel.new.first_name).to eq('sub_first_name')
  end

  specify "submodel should be able to inherit defaults" do
    expect(FactoryTest::NoDefaultModel.new.first_name).to eq('base_first_name')
  end

  specify "submodel should be able to inherit defaults" do
    expect(FactoryTest::NoDefaultModel.new.full_name).to eq('full_name')
  end

  specify "submodel should be able to override defaults" do
    a = FactoryTest::SubModel.new
    expect(a.first_name).to eq('sub_first_name')
    expect(a.last_name).to eq('sub_last_name')
    expect(a.attr_test).to eq('I came from SubModel')
    expect(a.base_attr).to eq('This is a base attribute')
  end

  specify "submodel should be able to add new keywords to the inherited set" do
    a = FactoryTest::KeywordsSubModel.new
    expect(a.middle_name).to eq('middle_name')
    expect(a.keywords.include?(:first_name)).to eq(true)
    expect(a.cat_name).to eq('Annie')
    expect(a.first_name).to eq('base_first_name')
    expect(a.dog_name).to eq('sugar')
  end

  specify "should not have duplicate keywords after inheritance" do
    a = FactoryTest::DuplicateKeywordsSubModel.new
    expect(a.keywords.select{|x| x == :first_name}.size).to be(1)
  end

end

describe "#hash_id" do
  class HashIdModel < Watirmark::Model::Factory
    keywords :first_name, :last_name
    defaults do
      first_name { "First" }
      middle_name { "Middle" }
      last_name { "Last #{hash_id}" }
    end
  end

  let(:model1) { HashIdModel.new }
  let(:model2) { HashIdModel.new }
  let(:model3) { HashIdModel.new }

  specify "HashIdModel should have a 8 digit hash_id and are always the same" do
    [model1, model2].each{|x| expect(x.last_name).to match(/^Last [a-f0-9]{8}$/)}
    expect(model1.last_name).to eq(model2.last_name)
  end

  specify "HashIdModels should have a hash_id of '4033fe24' when using the default seed 'Watirmark Default Seed'" do
    Watirmark::Configuration.instance.hash_id_seed = nil
    hash_id = (RUBY_VERSION == '1.9.3') ? 'ca14e5fb' : '4033fe24'
    expect(model1.hash_id).to eq(hash_id)
  end

  specify "HashIdModels should have a different 8 digit hash_id when they have different seeds" do
    model_seed_1 = HashIdModel.new
    Watirmark::Configuration.instance.hash_id_seed = "New Seed"
    model_seed_2 = HashIdModel.new
    Watirmark::Configuration.instance.hash_id_seed = "Newest Seed"
    model_seed_3 = HashIdModel.new
    Watirmark::Configuration.instance.hash_id_seed = nil

    [model_seed_1, model_seed_2, model_seed_3].each do |x|
      expect(x.last_name).to match(/^Last [a-f0-9]{8}$/)
    end
    expect([model_seed_1.last_name, model_seed_2.last_name, model_seed_3.last_name].uniq.length).to eq(3)
  end

  specify "add a new attribute to a HashIdModel with the hash_id" do
    model1.foo = "bar #{model1.hash_id}"
    model2.zoo = "baz #{model1.hash_id}"

    expect(model1.foo.gsub("bar", "baz")).to eq(model2.zoo)
    expect(HashIdModel.new.hash_id).to eq(HashIdModel.new.hash_id)
  end

  let(:test_strings) {
    ["0",
     "1",
     "a",
     "b",
     "This is quite a long test string",
     "This is quite a much longer test string that I'm going to use in my tests",
     "And one test string I'll use with special characters ©åßƒ"
    ]
  }

  specify "should generate a hash value with a length of 8 - the default" do
    new_model = Watirmark::Model::Factory.new
    keys = test_strings.map { |x| new_model.hash_id }
    keys.each { |x| expect(x.length).to eq(8) }
  end

  specify "should generate a hash value with a length of 20" do
    length = Watirmark::Configuration.instance.hash_id_length = 20
    new_model = Watirmark::Model::Factory.new
    keys = test_strings.map { |x| new_model.hash_id(length) }
    keys.each { |x| expect(x.length).to eq(20) }
  end

  specify "should generate a hash value with a length of 1" do
    length = Watirmark::Configuration.instance.hash_id_length = 1
    new_model = Watirmark::Model::Factory.new
    keys = test_strings.map { |x| new_model.hash_id(length) }
    keys.each { |x| expect(x.length).to eq(1) }
  end

  specify "should generate keys with hex values" do
    length = Watirmark::Configuration.instance.hash_id_length = 8
    new_model = Watirmark::Model::Factory.new
    keys = test_strings.map { |x| new_model.hash_id(length, :hex) }
    keys.each do |key|
      key.each_char do |char|
        expect(char[/[a-f0-9]/]).not_to be_nil
      end
    end
  end

  specify "should generate keys with alphanumeric values" do
    length = Watirmark::Configuration.instance.hash_id_length = 8
    new_model = Watirmark::Model::Factory.new
    keys = test_strings.map { |x| new_model.hash_id(length, :alpha) }
    keys.each do |key|
      key.each_char do |char|
        expect(char[/[A-Za-z0-9]/]).to_not be_nil
      end
    end
  end

end

describe "#uuid" do
  class UUIDModel < Watirmark::Model::Factory
    keywords :first_name, :last_name
    defaults do
      first_name { "First" }
      middle_name { "Middle" }
      last_name { "Last #{uuid}" }
    end
  end

  let(:model1) {UUIDModel.new}
  let(:model2) {UUIDModel.new}
  let(:model3) {UUIDModel.new}

  specify "UUIDModel should have a 10 digit uuid and are never the same" do
    [model1, model2].each{|x| expect(x.last_name).to match(/^Last [a-f0-9]{10}$/)}
    expect(model1.last_name).to_not eq(model2.last_name)
  end

  specify "UUIDModels should have a different 10 digit uuid when they are initialized with a different UUID" do
    model_seed_1 = UUIDModel.new
    Watirmark::Configuration.instance.uuid = "1234567890"
    model_seed_2 = UUIDModel.new
    Watirmark::Configuration.instance.uuid = "0987654321"
    model_seed_3 = UUIDModel.new

    [model_seed_1, model_seed_2, model_seed_3].each do |x|
      #puts x.last_name
      expect(x.last_name).to match(/^Last [a-f0-9]{10}$/)
    end
    expect([model_seed_1.last_name, model_seed_2.last_name, model_seed_3.last_name].uniq.length).to eq(3)
  end

  specify "UUIDModels should have different UUIDs if Watirmark::Configuration#uuid is not set" do
    Watirmark::Configuration.instance.uuid = nil
    expect(Watirmark::Configuration.instance.uuid).to be_nil
    expect(UUIDModel.new.uuid).to_not eq(UUIDModel.new.uuid)
  end

  specify "add a new attribute to a UUIDModel with the uuid" do
    model1.foo = "bar #{model1.uuid}"
    model2.zoo = "baz #{model1.uuid}"

    expect(model1.foo.gsub("bar", "baz")).to eq(model2.zoo)
  end

  after :all do
    Watirmark::Configuration.instance.uuid = nil
  end

end
