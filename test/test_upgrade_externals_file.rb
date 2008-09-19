$:.unshift File.join(File.dirname(__FILE__), '..', 'lib') if $0 == __FILE__
require 'externals/test_case'
require 'externals/ext'

module Externals
  class TestUpgradeExternalsFile < TestCase
    def test_upgrade
      Dir.chdir File.join(root_dir, 'test') do
        `rm -rf test_upgrade`
        `mkdir test_upgrade`


        Dir.chdir 'test_upgrade' do
          open '.externals', 'w' do |f|
            f.write "[main]

scm = git
type = rails
[git]

git://github.com/rails/rails.git
git://github.com/rails/acts_as_list.git:edge
[svn]

svn://rubyforge.org/var/svn/redhillonrails/trunk/vendor/plugins/foreign_key_migrations
svn://rubyforge.org/var/svn/redhillonrails/trunk/vendor/plugins/redhillonrails_core"
          end

          Ext.run "upgrade_externals_file"
          new_text = nil
          open '.externals', 'r' do |f|
            new_text = f.read
          end
          puts new_text

          config1 = Configuration::Configuration.new(new_text)

          config2 = Configuration::Configuration.new("[.]
scm = git
type = rails

[vendor/rails]
scm = git
repository = git://github.com/rails/rails.git

[vendor/plugins/acts_as_list]
scm = git
repository = git://github.com/rails/acts_as_list.git
branch = edge

[vendor/plugins/foreign_key_migrations]
scm = svn
repository = svn://rubyforge.org/var/svn/redhillonrails/trunk/vendor/plugins/foreign_key_migrations

[vendor/plugins/redhillonrails_core]
scm = svn
repository = svn://rubyforge.org/var/svn/redhillonrails/trunk/vendor/plugins/redhillonrails_core")


          assert(config1.sections.size == 5)

          [[config1, config2], [config2,config1]].each do |array|
            c1 = array[0]
            c2 = array[1]

            c1.sections.each do |section|
              s2 = c2[section.title]
              assert s2
              section.attributes.each_pair do |key,value|
                assert s2[key] == value
              end
            end
          end
        end

        `rm -rf test_upgrade`
      end
    end
  end
end