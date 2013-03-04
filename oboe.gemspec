$:.push File.expand_path("../lib", __FILE__)
require "oboe/version"

Gem::Specification.new do |s|
    s.name = %q{oboe}
    s.version = Oboe::Version::STRING
    s.date = Time.now.strftime('%Y-%m-%d')
    s.authors = ["Tracelytics, Inc."]
    s.email = %q{contact@tracelytics.com}
    s.summary = %q{Tracelytics instrumentation gem}
    s.homepage = %q{http://tracelytics.com}
    s.description = %q{The oboe gem provides AppNeta instrumentation for Ruby and Ruby frameworks.}
    s.extra_rdoc_files = ["LICENSE"]
    s.files = `git ls-files`.split("\n")
    s.extensions = ['ext/oboe_metal/extconf.rb']
    s.test_files  = Dir.glob("{spec}/**/*.rb")
    s.add_development_dependency 'rake'
    s.add_development_dependency 'rspec'
end
