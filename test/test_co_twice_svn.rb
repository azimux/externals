require_relative "support/prepare_test_suite"
require 'externals/ext'
require 'rails_app_svn_repository'

module Externals
  module Test
    class TestCoTwiceSvn < ::Test::Unit::TestCase
      include ExtTestCase

      def test_co_twice
        repository = RailsAppSvnRepository.new
        repository.prepare

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "checkout")
        rm_rf_ie workdir
        mkdir_p workdir

        source = repository.clean_url

        puts "About to checkout #{source}"
        Ext.run "checkout", "--svn", source, "-w", workdir, "rails_app"

        Dir.chdir workdir do
          Dir.chdir 'rails_app' do
            Ext.run "co", "modules"

            assert File.exist?('.svn')

            %w(redhillonrails_core acts_as_list).each do |proj|
              puts(ignore_text = `svn propget svn:ignore vendor/plugins`)
              assert(ignore_text =~ /^#{proj}$/)
            end

            puts(ignore_text = `svn propget svn:ignore vendor`)
            assert(ignore_text =~ /^rails$/)

            %w(redhillonrails_core acts_as_list some_subproject_with_edge).each do |proj|
              assert File.exist?(File.join('vendor', 'plugins', proj, 'lib'))
            end

            assert File.exist?(File.join('vendor', 'rails', 'activerecord', 'lib'))

            assert File.exist?(File.join('vendor', 'rails', '.git'))

            Dir.chdir File.join('vendor', 'rails') do
              heads = File.readlines("heads").map(&:strip)
              assert_equal 3, heads.size
              heads.each do |head|
                assert head =~ /^[0-9a-f]{40}$/
              end

              assert `git show #{heads[0]}` =~
                     /^\s*commit\s+#{heads[0]}\s*$/
            end

            assert File.exist?(File.join('modules', 'modules.txt'))

            assert File.read(File.join('modules', 'modules.txt')) =~ /line1 of/

            Dir.chdir File.join('vendor', 'plugins', 'some_subproject_with_edge') do
              assert(`git branch -a` =~ /^\*\s*edge\s*$/)
              assert(`git branch -a` !~ /^\*\s*master\s*$/)
            end
          end
        end
      end
    end
  end
end
