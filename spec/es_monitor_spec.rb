require 'spec_helper'

describe EsMonitor do
  describe EsMonitor::Client do
    let(:client) { EsMonitor::Client.new("http://localhost:9200") }
    
    describe "generating graphite URLs" do
      it "should nest the series_name as the first argument, given no modifiers" do
        client.graph_path("foo.bar").should == "foo.bar"
      end

      it "should nest a simple expression" do
        client.graph_path("foo.bar", {"sortByMaxima" => true}).should == "sortByMaxima(foo.bar)"
      end

      it "should nest a simple expression with an extra arg" do
        client.graph_path("foo.bar", {"aliasSub" => :baz}).should == "aliasSub(foo.bar,baz)"
      end

      it "should nest a simple expression with multiple args" do
        client.graph_path("foo.bar", {"aliasSub" => [:baz, :bot]}).should == "aliasSub(foo.bar,baz,bot)"
      end

      it "should nest a complex expression with all sorts of stuff happening" do
        client.graph_path("foo.bar", {
                            sortByMaxima: true, 
                            "aliasSub" => [:baz, :bot]
                          }).should == "aliasSub(sortByMaxima(foo.bar),baz,bot)"
      end

      it "should not allow non-Array, string, keyword and true modifier args" do
        expect {
          client.graph_path("foo.bar", {"aliasSub" => Object.new}).should
        }.to raise_error(ArgumentError)
      end
    end
  end
end
