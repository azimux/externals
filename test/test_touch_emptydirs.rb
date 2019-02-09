$:.unshift File.join(File.dirname(__FILE__),'..','lib') if $0 == __FILE__

require 'ext_test_case'
require 'externals/ext'

module Externals
  module Test
    class TestTouchEmptydirs < ::Test::Unit::TestCase
      include ExtTestCase

      def setup
        teardown

        Dir.chdir File.join(root_dir, 'test') do
          mkdir "workdir"

          Dir.chdir 'workdir' do
            mkdir "notempty1"
            Dir.chdir 'notempty1' do
              mkdir "notempty2"
              mkdir "empty1"
              Dir.chdir 'notempty2' do
                mkdir "empty2"
                mkdir "notempty3"
                Dir.chdir 'notempty3' do
                  File.open('readme.txt', 'w') do |f|
                    f.write "some text\n"
                  end
                end
              end
            end
          end
        end
      end

      def teardown
        Dir.chdir File.join(root_dir, 'test') do
          rm_rf "workdir"
        end
      end

      def test_touch_emptydirs
        Dir.chdir File.join(root_dir, 'test') do
          assert !File.exist?(File.join('.emptydir'))
          Dir.chdir 'workdir' do
            Ext.run "touch_emptydirs"
            assert !File.exist?(File.join('.emptydir'))
            assert !File.exist?(File.join('notempty1', '.emptydir'))
            assert File.exist?(File.join('notempty1', 'empty1', '.emptydir'))
            assert !File.exist?(File.join('notempty1', 'notempty2', '.emptydir'))
            assert File.exist?(File.join('notempty1', 'notempty2', 'empty2', '.emptydir'))
            assert !File.exist?(File.join('notempty1', 'notempty2', 'notempty3', '.emptydir'))
          end
        end
      end

    end
  end
end
