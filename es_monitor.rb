require 'sinatra'
require "sinatra/json"
require 'stretcher'

class EsMonitor < Sinatra::Base
  CLUSTERS = {
    "Andrew Localhost" => "http://localhost:9200"
  }

  METRICS = [:cluster_health, :storage]
  
  get '/' do
    
  end

  get '/overview.json' do
    json CLUSTERS.reduce({}) {|cluster_metrics,name_url|
      name, url = name_url
      client = Client.new(url)
      metrics = Hash.new {|h,k| h[k] = {}}
      cluster_metrics[name] = [:cluster_health].reduce(metrics) {|metrics,metric_name|
        metrics[metric_name] = client.send(metric_name)
        metrics
      }
      cluster_metrics
    }
  end


  class Client
    attr_reader :url
    
    def initialize(url)
      @url = url
    end

    def graphite
      @graphite_client ||= Faraday.new(:url => uri_components) do |builder|
        builder.request :multi_json
        builder.response :multi_json, :content_type => /\bjson$/
      end
    end
    
    # Ex:
    # graph("foo.bar", {
    #         sortByMaxima: true,
    #         aliasSub: :baz
    #       })
    # => aliasSub(sortByMaxima(foo.bar), "baz")
    #

    def graph_path(series_name, modifiers={})
      modifiers.keys.reduce(series_name) {|expr,modifier|
        # Check our input, does the current modifier have args expressed as something
        # arrayable? Note that +true+ is ignored, but allowed to pass to allow the first expr
        # to follow the syntax
        modifier_args = modifiers[modifier]
        unless [Array, String, Symbol].member?(modifier_args.class) || modifier_args == true
          raise ArgumentError, "Could not process modifier #{modifier}, bad argument in #{modifier_args}"
        end        
        
        # Cut out the true argument, always put the last expression into the first position
        arguments_rest = Array(modifier_args).reject {|a| a == true}
        arguments = arguments_rest.unshift expr # Unshift and save an Array!
        
        args_str = arguments.compact.join(",")
        "#{modifier}(#{args_str})"
      }
    end
    
    def cluster_health
      Stretcher::Server.with_server(url) do |server|
        server.cluster.health[:status]
      end
    end

    def storagea
      graph(:derivative, "elasticsearch.#{cluster_name}.*.ops.search.query.count")
      
      
    end
    
  end

end
