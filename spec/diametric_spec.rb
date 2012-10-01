require 'spec_helper'

class Person
  include Diametric

  attr :name, String, :index => true
  attr :email, String, :cardinality => :many
  attr :birthday, DateTime
  attr :awesome, :boolean, :doc => "Is this person awesome?"
  attr :ssn, String, :unique => :value
  attr :secret_name, String, :unique => :identity
  attr :bio, String, :fulltext => true
end

class Goat
  include Diametric

  attr :name, String
  attr :birthday, DateTime
end

describe Diametric do
  describe "in a class" do
    subject { Person }

    it { should respond_to(:attr) }
    it { should respond_to(:schema) }
    it { should respond_to(:query_data) }
    it { should respond_to(:from_query) }

    it "should generate a schema" do
      Person.schema.should == [
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/name",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/index" => true,
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/email",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/many",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/birthday",
          :"db/valueType" => :"db.type/instant",
          :"db/cardinality" => :"db.cardinality/one",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/awesome",
          :"db/valueType" => :"db.type/boolean",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/doc" => "Is this person awesome?",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/ssn",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/unique" => :"db.unique/value",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/secret_name",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/unique" => :"db.unique/identity",
          :"db.install/_attribute" => :"db.part/db" },
        { :"db/id" => Person.send(:tempid, :"db.part/db"),
          :"db/ident" => :"person/bio",
          :"db/valueType" => :"db.type/string",
          :"db/cardinality" => :"db.cardinality/one",
          :"db/fulltext" => true,
          :"db.install/_attribute" => :"db.part/db" }
      ]
    end
  end

  describe "in an instance" do
    subject { Person.new }

    it { should respond_to(:tx_data) }

    it "should handle attributes correctly" do
      subject.name.should be_nil
      subject.name = "Clinton"
      subject.name.should == "Clinton"
    end
  end

  describe ".new" do
    it "should work without arguments" do
      Person.new.should be_a(Person)
    end

    it "should assign attributes based off argument keys" do
      person = Person.new(:name => "Dashiell D", :secret_name => "Monito")
      person.name.should == "Dashiell D"
      person.secret_name.should == "Monito"
    end
  end

  describe ".from_query" do
    it "should assign dbid and attributes" do
      goat = Goat.from_query([1, "Beans", DateTime.parse("1976/9/4")])
      goat.dbid.should == 1
      goat.name.should == "Beans"
      goat.birthday.should == DateTime.parse("1976/9/4")
    end
  end

  describe "#query_data" do
    it "should generate a query given no arguments" do
      Goat.query_data.should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :from, ~"\$",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        {}
      ]
    end

    it "should generate a query given an argument" do
      Goat.query_data(:name => "Beans").should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :from, ~"\$", ~"?name",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        {:args => ["Beans"]}
      ]
    end

    it "should generate a query given multiple arguments" do
      bday = DateTime.parse("2003-09-04 11:30 AM")

      Goat.query_data(:name => "Beans", :birthday => bday).should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :from, ~"\$", ~"?name", ~"?birthday",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        {:args => ["Beans", bday]}
      ]
    end
  end

  describe "#tx_data" do
    let(:goat) { Goat.new(:name => "Beans", :birthday => Date.parse("2002-04-15"))}

    describe "without a dbid" do
      it "should generate a transaction with a new tempid" do
        # Equivalence is currently wrong on EDN tagged values.
        tx = goat.tx_data.first
        tx.keys.should == [:"db/id", :"goat/name", :"goat/birthday"]
        tx[:"db/id"].to_edn.should == "#db/id [:db.part/db]"
        tx[:"goat/name"].should == "Beans"
        tx[:"goat/birthday"].should == goat.birthday
      end
    end

    describe "with a dbid" do
      it "should generate a transaction with the dbid" do
        goat.dbid = 1
        goat.tx_data.should == [
          { :"db/id" => 1,
            :"goat/name" => "Beans",
            :"goat/birthday" => goat.birthday
          }
        ]
      end

      it "should generate a transaction with only specified attrs" do
        goat.dbid = 1
        goat.tx_data(:name).should == [
          { :"db/id" => 1,
            :"goat/name" => "Beans"
          }
        ]
      end
    end
  end
end
