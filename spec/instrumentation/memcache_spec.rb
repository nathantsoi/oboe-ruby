require 'spec_helper'
require 'memcache'

describe Oboe::API::Memcache do
  it 'Stock MemCache should be loaded, defined and ready' do
    defined?(::MemCache).should_not == nil 
  end

  it 'MemCache should have oboe methods defined' do
    Oboe::API::Memcache::MEMCACHE_OPS.each do |m|
      if ::MemCache.method_defined?(m)
        ::MemCache.method_defined?("#{m}_with_oboe").should == true 
      end
      ::MemCache.method_defined?(:request_setup_with_oboe).should == true 
      ::MemCache.method_defined?(:cache_get_with_oboe).should == true 
      ::MemCache.method_defined?(:get_multi_with_oboe).should == true 
    end
  end
end
