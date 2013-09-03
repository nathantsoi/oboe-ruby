# Copyright (c) 2012 by Tracelytics, Inc.
# All rights reserved.

module Oboe
  module API
    module Profiling 

      ##
      # Public: Profile a given block of code. Detect any exceptions thrown by
      # the block and report errors.
      #
      # profile_name - A name used to identify the block being profiled.
      # report_kvs - A hash containing key/value pairs that will be reported along
      # with the event of this profile (optional).
      #
      # Example
      #
      #   def computation(n)
      #     Oboe::API.profile('fib', { :n => n }) do
      #       fib(n)
      #     end
      #   end
      #
      # Returns the result of the block.
      def profile(profile_name, report_kvs={})
        
        report_kvs[:Language] ||= :ruby
        report_kvs[:ProfileName] ||= profile_name

        Oboe::Context.log(nil, 'profile_entry', report_kvs)

        begin 
          yield
        rescue Exception => e
          log_exception(nil, e) 
          raise
        ensure
          exit_kvs = {}
          exit_kvs[:Language] = :ruby
          exit_kvs[:ProfileName] = report_kvs[:ProfileName]

          Oboe::Context.log(nil, 'profile_exit', exit_kvs, false)
        end
      end
    end
  end
end
