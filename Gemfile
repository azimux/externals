require_relative "version"

source "https://rubygems.org"
ruby Externals::MINIMUM_RUBY_VERSION

# gemspec

gem "rake"

group :development do
  gem "foobara-rubocop-rules", ">= 1.1.0" # , path: "../../foobara/rubocop-rules"
  # gem "guard-rspec"
  gem "rubocop-rake"
end

group :development, :test do
  gem "pry"
  # gem "pry-byebug"
  # TODO: Just adding this to suppress warnings seemingly coming from pry-byebug. Can probably remove this once
  # pry-byebug has irb as a gem dependency
  gem "irb"
  gem "test-unit"
end

group :test do
  gem "ruby-prof"
  gem "simplecov"
end
