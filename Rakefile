
require 'rubygems'
require 'rubygems/package_task'

spec = Gem::Specification.new do |gem|
	gem.name          = "hiera-cloudformation"
	gem.version       = '0.0.1'
	gem.authors       = ["Hugh Cole-Baker"]
	gem.email         = ["hugh@fanduel.com"]
	gem.summary       = %q{CloudFormation backend for Hiera}
	gem.description   = %q{Queries CloudFormation stack outputs or resource metadata for Hiera data}
	gem.homepage      = ""
	gem.license       = "MIT"

	gem.files         = Dir['{bin,lib,man,test,spec}/**/*', 'Rakefile', 'README*', 'LICENSE*']
	gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
	gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
	gem.require_paths = ["lib"]

	gem.add_development_dependency "rake"
	gem.add_runtime_dependency "aws-sdk", "~> 1.11.2"
	gem.add_runtime_dependency "timedcache", "~> 0.4.0"
	gem.add_runtime_dependency "json", "~> 1.8.0"
end

Gem::PackageTask.new(spec) do |pkg|
	pkg.need_tar = true
end
