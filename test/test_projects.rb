$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'ext_test_case'
require 'externals/ext'

module Externals
  module Test
    class TestProjects < ::Test::Unit::TestCase
      include ExtTestCase

      def test_project_scm
        assert_equal "svn", SvnProject.scm
        assert_equal "git", GitProject.scm
        assert_raise RuntimeError do
          Project.scm
        end
      end

      def test_svn_global_opts
        Dir.chdir File.join(root_dir, 'test') do
          rm_rf "test_svn_global_opts" if File.exist?("test_svn_global_opts")
          mkdir "test_svn_global_opts"

          begin
            Dir.chdir 'test_svn_global_opts' do
              open '.externals', 'w' do |f|
                f.write "[.]
scm = git
type = rails

[vendor/plugins/acts_as_list]
scm = git
repository = git://github.com/rails/acts_as_list.git
branch = edge

[vendor/plugins/foreign_key_migrations]
scm = svn
repository = svn://rubyforge.org/var/svn/redhillonrails/trunk/vendor/plugins/foreign_key_migrations
                "
              end

              #test no scm_opts set...

              ext = Ext.new

              assert_equal ext.subproject_by_name_or_path('acts_as_list').scm_opts, nil
              assert_equal ext.subproject_by_name_or_path('acts_as_list').scm_opts_co, nil
              assert_equal ext.subproject_by_name_or_path('acts_as_list').scm_opts_up, nil
              assert_equal ext.main_project.scm_opts, nil
              assert_equal ext.main_project.scm_opts_co, nil
              assert_equal ext.main_project.scm_opts_up, nil
              assert_equal ext.main_project.git_opts, nil
              assert_equal ext.main_project.svn_opts, nil
              assert_equal ext.main_project.git_opts_up, nil
              assert_equal ext.main_project.svn_opts_up, nil


              open '.externals', 'w' do |f|
                f.write "[.]
scm = git
type = rails

[vendor/plugins/acts_as_list]
scm_opts = --verbose
scm = git
repository = git://github.com/rails/acts_as_list.git
branch = edge

[vendor/plugins/foreign_key_migrations]
scm_opts = --trust-server-cert --non-interactive
scm = svn
repository = svn://rubyforge.org/var/svn/redhillonrails/trunk/vendor/plugins/foreign_key_migrations
                "
              end

              #test scm_opts set... no _co, _up, etc.

              ext = Ext.new

              assert_equal ext.subproject_by_name_or_path('acts_as_list').scm_opts, "--verbose"
              assert_equal ext.subproject_by_name_or_path('acts_as_list').scm_opts_co, "--verbose"
              assert_equal ext.subproject_by_name_or_path('acts_as_list').scm_opts_up, "--verbose"
              assert_equal ext.subproject_by_name_or_path('foreign_key_migrations').scm_opts,
                "--trust-server-cert --non-interactive"
              assert_equal ext.subproject_by_name_or_path('foreign_key_migrations').scm_opts_co,
                "--trust-server-cert --non-interactive"
              assert_equal ext.subproject_by_name_or_path('foreign_key_migrations').scm_opts_up,
                "--trust-server-cert --non-interactive"
              assert_equal ext.main_project.scm_opts, nil
              assert_equal ext.main_project.scm_opts_co, nil
              assert_equal ext.main_project.scm_opts_up, nil
              assert_equal ext.main_project.git_opts, nil
              assert_equal ext.main_project.svn_opts, nil
              assert_equal ext.main_project.git_opts_up, nil
              assert_equal ext.main_project.svn_opts_up, nil

              #test global options and specific action options
              open '.externals', 'w' do |f|
                f.write "[.]
scm = git
type = rails
svn_opts = --trust-server-cert
svn_opts_up = --svn-up
git_opts = --verbose
scm_opts = --main-project-opts

[vendor/plugins/acts_as_list]
scm_opts_up = --made-up-option
scm = git
repository = git://github.com/rails/acts_as_list.git
branch = edge

[vendor/plugins/foreign_key_migrations]
scm_opts_co = --non-interactive
scm = svn
repository = svn://rubyforge.org/var/svn/redhillonrails/trunk/vendor/plugins/foreign_key_migrations
                "
              end

              ext = Ext.new

              assert_equal ext.subproject_by_name_or_path('acts_as_list').scm_opts, "--verbose"
              assert_equal ext.subproject_by_name_or_path('acts_as_list').scm_opts_co, "--verbose"
              assert_equal ext.subproject_by_name_or_path('acts_as_list').scm_opts_up,
                "--made-up-option --verbose"
              assert_equal ext.subproject_by_name_or_path('foreign_key_migrations').scm_opts,
                "--trust-server-cert"
              assert_equal ext.subproject_by_name_or_path('foreign_key_migrations').scm_opts_co,
                "--non-interactive --trust-server-cert"
              assert_equal ext.subproject_by_name_or_path('foreign_key_migrations').scm_opts_up,
                "--svn-up --trust-server-cert"
              assert_equal ext.main_project.scm_opts, "--main-project-opts --verbose"
              assert_equal ext.main_project.scm_opts_co, "--main-project-opts --verbose"
              assert_equal ext.main_project.scm_opts_up, "--main-project-opts --verbose"
              assert_equal ext.main_project.git_opts, "--verbose"
              assert_equal ext.main_project.svn_opts, "--trust-server-cert"
              assert_equal ext.main_project.git_opts_up, "--verbose"
              assert_equal ext.main_project.svn_opts_up, "--svn-up --trust-server-cert"

            end
          ensure
            rm_rf "test_svn_global_opts" if File.exist?("test_svn_global_opts")
          end

        end
      end
    end
  end
end
