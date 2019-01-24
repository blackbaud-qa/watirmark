require_relative 'spec_helper'

describe "Traits" do

  before :all do
    module Watirmark::Model
      trait :contact_name do
        first_name { "first" }
        last_name { "last_#{uuid}" }
      end

      trait :credit_card do
        cardnumber { 4111111111111111 }
      end
    end

    module FactoryTest
      class TraitsA < Watirmark::Model::Factory
        keywords :first_name, :last_name, :middle_name, :cardnumber
        traits :contact_name, :credit_card
        defaults do
          middle_name { "A" }
        end
      end

      class TraitsB < Watirmark::Model::Factory
        keywords :first_name, :last_name, :middle_name, :cardnumber
        traits :contact_name, :credit_card
        defaults do
          middle_name { "B" }
        end
      end

      class TraitsC < Watirmark::Model::Factory
        keywords :first_name
        defaults do
          first_name { "C" }
        end
        traits :contact_name, :credit_card
      end

      class TraitsD < Watirmark::Model::Factory
        keywords :first_name
        traits :contact_name, :credit_card
        defaults do
          first_name { "D" }
        end
      end
    end
  end

  before :all do
    # guard against other tests setting UUID
    Watirmark::Configuration.instance.uuid = nil
  end

  specify "should have different last names" do
    a = FactoryTest::TraitsA.new
    b = FactoryTest::TraitsB.new
    expect(a.middle_name).not_to eq(b.middle_name)
  end

  specify "should have same first names" do
    a = FactoryTest::TraitsA.new
    b = FactoryTest::TraitsB.new
    expect(a.first_name).to eq(b.first_name)
  end

  specify "should have same last name but with different UUID" do
    a = FactoryTest::TraitsA.new
    b = FactoryTest::TraitsB.new
    expect(a.last_name).to include("last")
    expect(b.last_name).to include("last")
    expect(a.last_name).not_to eq(b.last_name)
  end

  specify "should have same credit card number" do
    a = FactoryTest::TraitsA.new
    b = FactoryTest::TraitsB.new
    expect(a.cardnumber).to eq(b.cardnumber)
  end

  specify "defaults should take precedence over traits" do
    expect(FactoryTest::TraitsC.new.first_name).to eq("C")
    expect(FactoryTest::TraitsD.new.first_name).to eq("D")
  end
end

describe "Nested Traits" do

  before :all do
    module Watirmark::Model
      trait :credit_card do
        credit_card {4111111111111111}
      end

      trait :donor_address do
        donor_address { "123 Sunset St" }
        donor_state { "TX" }
      end

      trait :donor_jim do
        traits :donor_address
        first_name { "Jim" }
        last_name { "Smith" }
      end

      trait :donor_jane do
        first_name { "Jane" }
        last_name { "Baker" }
        traits :donor_address, :credit_card
      end
    end

    module FactoryTest
      class Jim < Watirmark::Model::Factory
        keywords :first_name, :last_name, :donor_address, :donor_state, :credit_card
        traits :donor_jim
      end

      class Jane < Watirmark::Model::Factory
        keywords :first_name, :last_name, :donor_address, :donor_state, :credit_card
        traits :donor_jane
      end
    end

  end

  specify "should have different first and last name" do
    jim = FactoryTest::Jim.new
    jane = FactoryTest::Jane.new
    expect(jim.first_name).not_to eq(jane.first_name)
    expect(jim.last_name).not_to eq(jane.last_name)
  end

  specify "should have same address due to same trait" do
    jim = FactoryTest::Jim.new
    jane = FactoryTest::Jane.new
    expect(jim.donor_address).to eq("123 Sunset St")
    expect(jim.donor_state).to eq("TX")
    expect(jim.donor_address).to eq(jim.donor_address)
    expect(jim.donor_state).to eq(jim.donor_state)
    expect(jane.credit_card).to eq(4111111111111111)
  end
end

