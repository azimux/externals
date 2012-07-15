$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'
require 'externals/test/rails_app_git_repository'

module Externals
  module Test
    class TestFreezeToRevision < TestCase
      include ExtTestCase

      def test_freeze_to_revision
        repository = RailsAppGitRepository.new
        repository.prepare

        assert File.exists?(repository.clean_dir)

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "checkout", "git")
        mkdir_p workdir

        Dir.chdir workdir do
          rm_r repository.name if File.exists? repository.name
          source = repository.clean_dir
          puts "About to checkout #{source}"
          Ext.run "checkout", "--git", source

          Dir.chdir repository.name do
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
                  raise unless $? == 0
                end
              end

              Dir.chdir 'foreign_key_migrations' do
                assert `svn info` =~ /^.*:\s*2\s*$/i
              end
            end

            ext = Ext.new
            acts_as_list = ext.subproject("acts_as_list")

            assert `git show HEAD` !~ /^\s*commit\s*8771a632dc26a7782800347993869c964133ea29\s*$/i
            raise unless $? == 0
            r = repository.dependents[:acts_as_list].attributes[:revision]
            assert r =~ /^[a-f0-9]{40}$/
            assert_equal r,
              acts_as_list.current_revision
            `git show HEAD` =~ /^\s*commit\s*#{r}\s*$/i
            raise unless $? == 0

            %w(foreign_key_migrations redhillonrails_core acts_as_list).each do |proj|
              assert File.exists?(File.join('vendor', 'plugins', proj, 'lib'))
            end
          end
        end
      end

    end
  end
end