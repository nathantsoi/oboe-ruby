# Copyright (c) 2012 by Tracelytics, Inc.
# All rights reserved.

module Oboe
  module Inst
    module Moped
      FLAVOR = 'mongodb'

      # Moped::Database
      DB_OPS         = [ :command, :drop ]

      # Moped::Indexes
      INDEX_OPS      = [ :create, :drop ]

      # Moped::Query
      QUERY_OPS      = [ :count, :sort, :limit, :distinct, :update, :update_all, :upsert, 
                         :explain, :modify, :remove, :remove_all ]

      # Moped::Collection
      COLLECTION_OPS = [ :drop, :find, :indexes, :insert, :aggregate ]
    end
  end
end

if defined?(::Moped) and Oboe::Config[:moped][:enabled]
  Oboe.logger.info "[oboe/loading] Instrumenting moped" if Oboe::Config[:verbose]

  if defined?(::Moped::Database)
    module ::Moped
      class Database
        include Oboe::Inst::Moped
        
        def extract_trace_details(op)
          report_kvs = {}
          begin
            report_kvs[:Flavor] = Oboe::Inst::Moped::FLAVOR
            # FIXME: We're only grabbing the first of potentially multiple servers here
            report_kvs[:RemoteHost], report_kvs[:RemotePort] = session.cluster.seeds.first.split(':')
            report_kvs[:Database] = name
            report_kvs[:QueryOp] = op.to_s
          rescue
          end
          report_kvs
        end
       
        def command_with_oboe(command)
          if Oboe.tracing? and not Oboe::Context.layer_op and command.has_key?(:mapreduce)
            report_kvs = extract_trace_details(:map_reduce)
            report_kvs[:Map_Function] = command[:map]
            report_kvs[:Reduce_Function] = command[:reduce]

            Oboe::API.trace('mongo', report_kvs) do
              command_without_oboe(command)
            end
          else
            command_without_oboe(command)
          end
        end

        def drop_with_oboe
          if Oboe.tracing?
            report_kvs = extract_trace_details(:drop_database)

            Oboe::API.trace('mongo', report_kvs) do
              drop_without_oboe
            end
          else
            drop_without_oboe
          end
        end
        
        Oboe::Inst::Moped::DB_OPS.each do |m|
          if method_defined?(m)
            class_eval "alias #{m}_without_oboe #{m}"
            class_eval "alias #{m} #{m}_with_oboe"
          else Oboe.logger.warn "[oboe/loading] Couldn't properly instrument moped (#{m}).  Partial traces may occur."
          end
        end
      end
    end
  end

  if defined?(::Moped::Indexes)
    module ::Moped
      class Indexes 
        include Oboe::Inst::Moped
        
        def extract_trace_details(op)
          report_kvs = {}
          begin
            report_kvs[:Flavor] = Oboe::Inst::Moped::FLAVOR
            # FIXME: We're only grabbing the first of potentially multiple servers here
            report_kvs[:RemoteHost], report_kvs[:RemotePort] = database.session.cluster.seeds.first.split(':')
            report_kvs[:Database] = database.name
            report_kvs[:QueryOp] = op.to_s
          rescue
          end
          report_kvs
        end
        
        def create_with_oboe(key, options = {})
          if Oboe.tracing?
            # We report :create_index here to be consistent
            # with other mongo implementations
            report_kvs = extract_trace_details(:create_index)
            report_kvs[:Key] = key.try(:to_json)
            report_kvs[:Options] = options.try(:to_json)

            Oboe::API.trace('mongo', report_kvs, :create_index) do
              create_without_oboe(key, options = {})
            end
          else
            create_without_oboe(key, options = {})
          end
        end
        
        def drop_with_oboe(key = nil)
          if Oboe.tracing?
            # We report :drop_indexes here to be consistent
            # with other mongo implementations
            report_kvs = extract_trace_details(:drop_indexes)
            report_kvs[:Key] = key.nil? ? "all" : key.try(:to_json)

            Oboe::API.trace('mongo', report_kvs) do
              drop_without_oboe(key = nil)
            end
          else
            drop_without_oboe(key = nil)
          end
        end

        Oboe::Inst::Moped::INDEX_OPS.each do |m|
          if method_defined?(m)
            class_eval "alias #{m}_without_oboe #{m}"
            class_eval "alias #{m} #{m}_with_oboe"
          else Oboe.logger.warn "[oboe/loading] Couldn't properly instrument moped (#{m}).  Partial traces may occur."
          end
        end
      end
    end
  end

  if defined?(::Moped::Query)
    module ::Moped
      class Query
        include Oboe::Inst::Moped


        def extract_trace_details(op)
          report_kvs = {}
          begin
            report_kvs[:Flavor] = Oboe::Inst::Moped::FLAVOR
            # FIXME: We're only grabbing the first of potentially multiple servers here
            report_kvs[:RemoteHost], report_kvs[:RemotePort] = collection.database.session.cluster.seeds.first.split(':')
            report_kvs[:Database] = collection.database.name
            report_kvs[:Collection_Name] = collection.name
            report_kvs[:QueryOp] = op.to_s
          rescue
          end
          report_kvs
        end
        
        def count_with_oboe
          if Oboe.tracing?
            report_kvs = extract_trace_details(:count)
            report_kvs[:Query] = selector.try(:empty?) ? "all" : selector.try(:to_json)

            Oboe::API.trace('mongo', report_kvs) do
              count_without_oboe
            end
          else
            count_without_oboe
          end
        end

        def sort_with_oboe(sort)
          if Oboe.tracing?
            report_kvs = extract_trace_details(:sort)
            report_kvs[:Query] = selector.try(:empty?) ? "all" : selector.try(:to_json)
            report_kvs[:Order] = sort.to_s

            Oboe::API.trace('mongo', report_kvs) do
              sort_without_oboe(sort)
            end
          else
            sort_without_oboe(sort)
          end
        end
        
        def limit_with_oboe(limit)
          if Oboe.tracing? and not Oboe::Context.tracing_layer_op?(:explain)
            report_kvs = extract_trace_details(:limit)
            report_kvs[:Query] = selector.try(:empty?) ? "all" : selector.try(:to_json)
            report_kvs[:Limit] = limit.to_s

            Oboe::API.trace('mongo', report_kvs) do
              limit_without_oboe(limit)
            end
          else
            limit_without_oboe(limit)
          end
        end

        def distinct_with_oboe(key)
          if Oboe.tracing?
            report_kvs = extract_trace_details(:distinct)
            report_kvs[:Query] = selector.try(:empty?) ? "all" : selector.try(:to_json)
            report_kvs[:Key] = key.to_s

            Oboe::API.trace('mongo', report_kvs) do
              distinct_without_oboe(key)
            end
          else
            distinct_without_oboe(key)
          end
        end
        
        def update_with_oboe(change, flags = nil)
          if Oboe.tracing? and not Oboe::Context.tracing_layer_op?([:update_all, :upsert])
            report_kvs = extract_trace_details(:update)
            report_kvs[:Flags] = flags.to_s if flags
            report_kvs[:Update_Document] = change.try(:to_json)

            Oboe::API.trace('mongo', report_kvs) do
              update_without_oboe(change, flags = nil)
            end
          else
            update_without_oboe(change, flags = nil)
          end
        end
        
        def update_all_with_oboe(change)
          if Oboe.tracing?
            report_kvs = extract_trace_details(:update_all)
            report_kvs[:Update_Document] = change.try(:to_json)

            Oboe::API.trace('mongo', report_kvs, :update_all) do
              update_all_without_oboe(change)
            end
          else
            update_all_without_oboe(change)
          end
        end

        def upsert_with_oboe(change)
          if Oboe.tracing?
            report_kvs = extract_trace_details(:upsert)
            report_kvs[:Query] = selector.try(:to_json)
            report_kvs[:Update_Document] = change.try(:to_json)

            Oboe::API.trace('mongo', report_kvs, :upsert) do
              upsert_without_oboe(change)
            end
          else
            upsert_without_oboe(change)
          end
        end

        def explain_with_oboe
          if Oboe.tracing?
            report_kvs = extract_trace_details(:explain)
            report_kvs[:Query] = selector.try(:empty?) ? "all" : selector.try(:to_json)

            Oboe::API.trace('mongo', report_kvs, :explain) do
              explain_without_oboe
            end
          else
            explain_without_oboe
          end
        end

        def modify_with_oboe(change, options = {})
          if Oboe.tracing?
            report_kvs = extract_trace_details(:modify)
            report_kvs[:Update_Document] = selector.try(:empty?) ? "all" : selector.try(:to_json)
            report_kvs[:Change] = change.try(:to_json)
            report_kvs[:Options] = options.try(:to_json)

            Oboe::API.trace('mongo', report_kvs) do
              modify_without_oboe(change, options)
            end
          else
            modify_without_oboe(change, options)
          end
        end
        
        def remove_with_oboe
          if Oboe.tracing?
            report_kvs = extract_trace_details(:remove)
            report_kvs[:Query] = selector.try(:to_json)

            Oboe::API.trace('mongo', report_kvs) do
              remove_without_oboe
            end
          else
            remove_without_oboe
          end
        end

        def remove_all_with_oboe
          if Oboe.tracing?
            report_kvs = extract_trace_details(:remove_all)
            report_kvs[:Query] = selector.try(:to_json)

            Oboe::API.trace('mongo', report_kvs) do
              remove_all_without_oboe
            end
          else
            remove_all_without_oboe
          end
        end

        Oboe::Inst::Moped::QUERY_OPS.each do |m|
          if method_defined?(m)
            class_eval "alias #{m}_without_oboe #{m}"
            class_eval "alias #{m} #{m}_with_oboe"
          else Oboe.logger.warn "[oboe/loading] Couldn't properly instrument moped (#{m}).  Partial traces may occur."
          end
        end
      end
    end
  end # ::Moped::Query


  if defined?(::Moped::Collection)
    module ::Moped
      class Collection
        include Oboe::Inst::Moped

        def extract_trace_details(op)
          report_kvs = {}
          begin
            report_kvs[:Flavor] = Oboe::Inst::Moped::FLAVOR
            # FIXME: We're only grabbing the first of potentially multiple servers here
            report_kvs[:RemoteHost], report_kvs[:RemotePort] = @database.session.cluster.seeds.first.split(':')
            report_kvs[:Database] = @database.name
            report_kvs[:Collection_Name] = @name
            report_kvs[:QueryOp] = op.to_s
          rescue
          end
          report_kvs
        end

        def drop_with_oboe
          if Oboe.tracing?
            # We report :drop_collection here to be consistent
            # with other mongo implementations
            report_kvs = extract_trace_details(:drop_collection)

            Oboe::API.trace('mongo', report_kvs) do
              drop_without_oboe
            end
          else
            drop_without_oboe
          end
        end

        def find_with_oboe(selector = {})
          if Oboe.tracing?
            report_kvs = extract_trace_details(:find)
            report_kvs[:Query] = selector.try(:empty?) ? "all" : selector.try(:to_json)

            Oboe::API.trace('mongo', report_kvs) do
              find_without_oboe(selector)
            end
          else
            find_without_oboe(selector)
          end
        end
        
        def indexes_with_oboe
          if Oboe.tracing?
            report_kvs = extract_trace_details(:indexes)

            Oboe::API.trace('mongo', report_kvs) do
              indexes_without_oboe
            end
          else
            indexes_without_oboe
          end
        end
        
        def insert_with_oboe(documents, flags = nil)
          if Oboe.tracing? and not Oboe::Context.tracing_layer_op?(:create_index)
            report_kvs = extract_trace_details(:insert)

            Oboe::API.trace('mongo', report_kvs) do
              insert_without_oboe(documents, flags)
            end
          else
            insert_without_oboe(documents, flags)
          end
        end
        
        def aggregate_with_oboe(pipeline)
          if Oboe.tracing?
            report_kvs = extract_trace_details(:aggregate)

            Oboe::API.trace('mongo', report_kvs) do
              aggregate_without_oboe(pipeline)
            end
          else
            aggregate_without_oboe(pipeline)
          end
        end
        
        Oboe::Inst::Moped::COLLECTION_OPS.each do |m|
          if method_defined?(m)
            class_eval "alias #{m}_without_oboe #{m}"
            class_eval "alias #{m} #{m}_with_oboe"
          else Oboe.logger.warn "[oboe/loading] Couldn't properly instrument moped (#{m}).  Partial traces may occur."
          end
        end
      end
    end
  end # ::Moped::Collection
end
