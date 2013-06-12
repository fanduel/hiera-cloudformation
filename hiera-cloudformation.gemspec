# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
	spec.name          = "hiera-cloudformation"
	spec.version       = '0.0.1'
	spec.authors       = ["Hugh Cole-Baker"]
	spec.email         = ["hugh@fanduel.com"]
	spec.description   = %q{CloudFormation backend for Hiera}
	spec.summary       = %q{Queries CloudFormation metadata for Hiera data}
	spec.homepage      = ""
	spec.license       = "MIT"

	spec.files         = `git ls-files`.split($/)
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]

	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rake"
	spec.add_runtime_dependency "aws-sdk", "~>1.11.2"
	spec.add_runtime_dependency "timedcache", "~>0.4.0"
end
