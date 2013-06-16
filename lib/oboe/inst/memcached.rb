# Copyright (c) 2012 by Tracelytics, Inc.
# All rights reserved.
#

module Oboe
  module Inst
    module Memcached
      include Oboe::API::Memcache
      
      def self.included(cls)
        Oboe.logger.info "[oboe/loading] Instrumenting memcached" if Oboe::Config[:verbose]

        cls.class_eval do
          MEMCACHE_OPS.reject { |m| not method_defined?(m) }.each do |m|
            define_method("#{m}_with_oboe") do |*args|
              opts = { :KVOp => m }
              if args.length and args[0].class != Array
                opts[:KVKey] = args[0].to_s
                rhost = remote_host(args[0].to_s)
                opts[:RemoteHost] = rhost if rhost
              end

              Oboe::API.trace('memcache', opts) do
                result = send("#{m}_without_oboe", *args)
                if m == :get and args.length and args[0].class == String
                  Oboe::API.log('memcache', 'info', { :KVHit => memcache_hit?(result) })
                end
                result
              end
            end

            class_eval "alias #{m}_without_oboe #{m}"
            class_eval "alias #{m} #{m}_with_oboe"
          end
        end
      end

    end # module Memcached

    module MemcachedRails
      def self.included(cls)
        cls.class_eval do
          if ::Memcached::Rails.method_defined? :get_multi
            alias get_multi_without_oboe get_multi
            alias get_multi get_multi_with_oboe
          elsif Oboe::Config[:verbose]
            Oboe.logger.warn "[oboe/loading] Couldn't properly instrument Memcached.  Partial traces may occur." 
          end
        end
      end

      def get_multi_with_oboe(keys, raw=false)
        if Oboe.tracing?
          layer_kvs = {}
          layer_kvs[:KVOp] = :get_multi

          Oboe::API.trace('memcache', layer_kvs || {}, :get_multi) do
            begin
              info_kvs = {}
              info_kvs[:KVKeyCount] = keys.flatten.length 

              values = get_multi_without_oboe(keys, raw)
              
              info_kvs[:KVHitCount] = values.length
              Oboe::API.log('memcache', 'info', info_kvs)
            rescue
              values = get_multi_without_oboe(keys, raw)
            end
            values 
          end
        else
          get_multi_without_oboe(keys, raw)
        end
      end

    end # module MemcachedRails
  end # module Inst
end # module Oboe

if defined?(::Memcached) and Oboe::Config[:memcached][:enabled]
  ::Memcached.class_eval do
    include Oboe::Inst::Memcached
  end
  
  if defined?(::Memcached::Rails)
    ::Memcached::Rails.class_eval do
      include Oboe::Inst::MemcachedRails
    end
  end
end

