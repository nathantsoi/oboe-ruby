require 'spec_helper'
require 'memcached'
require 'memcached/rails'

describe Oboe::Inst::Memcached do
  it 'Stock Memcached should be loaded, defined and ready' do
    defined?(::Memcached).should_not == nil 
    defined?(::Memcached::Rails).should_not == nil 
  end

  it 'Memcached should have oboe methods defined' do
    Oboe::API::Memcache::MEMCACHE_OPS.each do |m|
      if ::Memcached.method_defined?(m)
        ::Memcached.method_defined?("#{m}_with_oboe").should == true 
      end
      ::Memcached::Rails.method_defined?(:get_multi_with_oboe).should == true 
    end
  end
end
