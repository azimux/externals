$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestFreezeToRevision < TestCase
    include ExtTestCase

    def setup
      destroy_rails_application
      create_rails_application

      Dir.chdir File.join(root_dir, 'test') do
        parts = 'workdir/checkout/rails_app/vendor/plugins/foreign_key_migrations/lib/red_hill_consulting/foreign_key_migrations/active_record/connection_adapters/.svn/text-base/table_definition.rb.svn-base'.split('/')
        if File.exists? File.join(*parts)
          Dir.chdir File.join(*(parts[0..-2])) do
            File.delete parts[-1]
          end
        end
        `rm -rf workdir`
        `mkdir workdir`
        `cp -r #{rails_application_dir} workdir`
        Dir.chdir File.join('workdir','rails_app') do
          Ext.run "touch_emptydirs"

          `git init`
          Ext.run "init"
          raise " could not create .externals"  unless File.exists? '.externals'
          Ext.run "install", File.join(root_dir, 'test', 'cleanreps', "acts_as_list.git")

          #install a couple svn managed subprojects
          %w(foreign_key_migrations redhillonrails_core).each do |proj|
            Ext.run "install", "--svn", 'file:///' + File.join(root_dir, 'test', 'cleanreps', proj)
          end

          Ext.run "freeze", "foreign_key_migrations", "2"
          Ext.run "freeze", "acts_as_list", "9baff190a52c05cc542bfcaa7f77a91ce669f2f8"

          GitProject.add_all
          `git commit -m "created empty rails app with some subprojects"`
        end
      end
    end

    def teardown
      destroy_rails_application

      Dir.chdir File.join(root_dir, 'test') do
        parts = 'workdir/checkout/rails_app/vendor/plugins/foreign_key_migrations/lib/red_hill_consulting/foreign_key_migrations/active_record/connection_adapters/.svn/text-base/table_definition.rb.svn-base'.split('/')
        if File.exists? File.join(*parts)
          Dir.chdir File.join(*(parts[0..-2])) do
            File.delete parts[-1]
          end
        end
        `rm -rf workdir`
      end
      Dir.chdir File.join(root_dir, 'test') do
        `rm -rf workdir`
      end
    end


    def test_freeze_to_revision
      Dir.chdir File.join(root_dir, 'test') do
        Dir.chdir 'workdir' do
          `mkdir checkout`
          Dir.chdir 'checkout' do
            source = File.join(root_dir, 'test', 'workdir', 'rails_app')
            puts "About to checkout #{ source}"
            Ext.run "checkout", "--git", source

            Dir.chdir 'rails_app' do
              assert File.exists?('.git')

              assert File.exists?('.gitignore')

              %w(foreign_key_migrations redhillonrails_core acts_as_list).each do |proj|
                assert(File.read('.gitignore') =~ /^vendor[\/\\]plugins[\/\\]#{proj}$/)
              end

              Dir.chdir File.join('vendor', 'plugins') do
                Dir.chdir 'acts_as_list' do
                  %w(8771a632dc26a7782800347993869c964133ea29
                  27a941c80ccaa8afeb9bfecb84c0ff098d8ba962
                  9baff190a52c05cc542bfcaa7f77a91ce669f2f8
                  ).each do |hash|
                    assert `git show #{hash}` =~ /^commit\s*#{hash}$/i
                  end
                  assert `git show HEAD` !~ /^\s*commit\s*8771a632dc26a7782800347993869c964133ea29\s*$/i
                  assert `git show HEAD` =~ /^\s*commit\s*9baff190a52c05cc542bfcaa7f77a91ce669f2f8\s*$/i
                end

                Dir.chdir 'foreign_key_migrations' do
                  assert `svn info` =~ /^Revision:\s*2\s*$/i
                end
              end

              %w(foreign_key_migrations redhillonrails_core acts_as_list).each do |proj|
                assert File.exists?(File.join('vendor', 'plugins',proj, 'lib'))
              end
            end
          end
        end
      end
    end
  end
end