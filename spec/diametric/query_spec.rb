require 'spec_helper'

describe Diametric::Query do
  let(:query) { Diametric::Query.new(Goat) }

  describe "#where" do
    it "is non-destructive" do
      query.where(:age => 2)
      query.conditions.should be_empty
    end
  end

  describe "#filter" do
    it "is non-destructive" do
      query.filter(:<, :age, 2)
      query.filters.should be_empty
    end
  end


  describe "#data" do
    it "should generate a query given no conditions or filters" do
      query.data.should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :in, ~"\$",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        []
      ]
    end

    it "should generate a query given a condition" do
      query.where(:name => "Beans").data.should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :in, ~"\$", ~"?name",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        ["Beans"]
      ]
    end

    it "should generate a query given multiple conditions" do
      bday = DateTime.parse("2003-09-04 11:30 AM")

      query.where(:name => "Beans", :birthday => bday).data.should == [
        [
          :find, ~"?e", ~"?name", ~"?birthday",
          :in, ~"\$", ~"?name", ~"?birthday",
          :where,
          [~"?e", :"goat/name", ~"?name"],
          [~"?e", :"goat/birthday", ~"?birthday"]
        ],
        ["Beans", bday]
      ]
    end
  end
end
