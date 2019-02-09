$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'ext_test_case'
require 'externals/ext'
require 'rails_app_git_repository'
require 'basic_git_repository'
require 'modules_svn_branches_repository'

module Externals
  module Test
    class TestFreezeToRevision < ::Test::Unit::TestCase
      include ExtTestCase

      def test_freeze_to_revision
        repository = RailsAppGitRepository.new
        repository.prepare

        assert File.exist?(repository.clean_dir)

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "checkout", "git")
        mkdir_p workdir

        Dir.chdir workdir do
          rm_r repository.name if File.exist?(repository.name)
          source = repository.clean_dir
          puts "About to checkout #{source}"
          Ext.run "checkout", "--git", source

          Dir.chdir repository.name do
            assert File.exist?('.git')

            assert File.exist?('.gitignore')

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
              assert File.exist?(File.join('vendor', 'plugins', proj, 'lib'))
            end
          end
        end
      end

      def test_svn_freeze_with_branch
        repository = BasicGitRepository.new
        repository.prepare

        sub_repository = ModulesSvnBranchesRepository.new
        sub_repository.prepare

        assert File.exist?(repository.clean_dir)

        workdir = File.join(root_dir, 'test', "tmp", "workdir", "checkout", "git")
        mkdir_p workdir

        Dir.chdir workdir do
          rm_r repository.name if File.exist?(repository.name)
          source = repository.clean_dir

          puts "About to checkout #{source}"
          `git clone #{source}`
          raise unless $? == 0


          Dir.chdir repository.name do
            Ext.run "init"

            sub_source = sub_repository.clean_url
            Ext.run "install", "--svn", sub_source, "-b", "branches/branch2", "modules"

            ext = Ext.new
            subproject = ext.subproject_by_name_or_path("modules")

            assert_equal subproject.current_branch, "branches/branch2"
            assert_equal subproject.current_revision, "4"

            # let's freeze the revision to 3
            Ext.run "freeze", "modules", "3"
            assert_equal subproject.current_revision, "3"

            # let's check this stuff in to test checking it out...
            `git add .gitignore .externals`
            raise unless $? == 0

            repository.mark_dirty

            `git commit -m "froze modules to revision 3"`
            raise unless $? == 0
            `git push`
            raise unless $? == 0
          end
        end

        rm_rf workdir
        mkdir_p workdir

        Dir.chdir workdir do
          rm_r repository.name if File.exist?(repository.name)
          source = repository.clean_dir

          puts "About to checkout #{source}"
          Ext.run "checkout", "--git", source

          Dir.chdir repository.name do
            ext = Ext.new
            subproject = ext.subproject_by_name_or_path("modules")

            assert_equal subproject.current_branch, "branches/branch2"
            assert_equal subproject.current_revision, "3"

            # now let's test unfreezing...
            Ext.run "unfreeze", "modules"
            assert_equal subproject.current_branch, "branches/branch2"
            assert_equal subproject.current_revision, "4"

            # Check it in to make sure it sticks
            `git add .externals`
            raise unless $? == 0
            `git commit -m "unfreezing modules"`
            raise unless $? == 0
            `git push`
            raise unless $? == 0
          end
        end

        rm_rf workdir
        mkdir_p workdir

        Dir.chdir workdir do
          rm_r repository.name if File.exist?(repository.name)
          source = repository.clean_dir

          puts "About to checkout #{source}"
          Ext.run "checkout", "--git", source

          Dir.chdir repository.name do
            ext = Ext.new
            subproject = ext.subproject_by_name_or_path("modules")

            assert_equal subproject.current_branch, "branches/branch2"
            assert_equal subproject.current_revision, "4"
          end
        end
      end

    end
  end
end
