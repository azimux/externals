require_relative "version"

Gem::Specification.new do |specification|
  specification.name = 'ext'
  specification.version = Externals::VERSION

  specification.summary =
    "Provides an SCM agnostic way to manage subprojects with a workflow similar
to the svn:externals feature of subversion instead of that of git submodules."

  specification.author = "Miles Georgi"
  specification.email = "azimux@gmail.com"
  specification.homepage = "http://nopugs.com/ext-tutorial"

  specification.required_ruby_version = Externals::MINIMUM_RUBY_VERSION

  specification.bindir = "bin"
  specification.executables = ['ext']

  specification.license = "MPL-2.0"

  specification.metadata["homepage_uri"] = spec.homepage
  specification.metadata["source_code_uri"] = spec.homepage
  specification.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  specification.files = Dir[
                             "bin/ext",
                             "lib/**/*",
                             "LICENSE*.txt",
                             "README*",
                             "CHANGELOG*",
                             "version.rb"
                           ]

  specification.require_paths = ["lib"]
  specification.metadata['rubygems_mfa_required'] = 'true'
end
