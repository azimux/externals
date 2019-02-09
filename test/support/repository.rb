require 'fileutils'

module Externals
  module Test

    # repositories used for testing live in
    #
    # test/tmp/cleanreps
    #
    # and a backup is made in
    #
    # test/tmp/pristinereps
    #
    # reps in pristinereps are never written to, but a test can write to
    # a rep in cleanreps.  When this happens, the test needs to reset
    # the rep in cleanreps.  This can be done by simply deleting it.  It
    # will then be copied back over from pristinereps.
    #
    # a file is placed in these directories named .working_#{repname}
    # when they are being built or copied.  If present, Repository will not use
    # that folder, and will instead delete it and recreate it.
    #
    class Repository
      include ExtTestCase

      attr_accessor :name, :subpath, :dependents, :attributes

      def initialize name, subpath = ""
        self.subpath = subpath
        self.name = name
        self.dependents ||= {}
        self.attributes ||= {}

        [
          clean_dir_parent,
          pristine_dir_parent
        ].each do |p|
          FileUtils.mkdir_p p
        end
      end

      # the root location under which all clean repositories are stored for testing.
      def clean_dir_root
        File.join(root_dir, "test", "tmp", "cleanreps")
      end

      # One level up from the directory in which this repository's clean version is stored
      def clean_dir_parent
        if subpath.empty?
          clean_dir_root
        else
          File.join clean_dir_root, subpath
        end
      end

      # The directory in which this repository's clean version is stored
      def clean_dir
        File.join clean_dir_parent, name
      end

      # the root location under which all pristine repositories are stored for testing.
      def pristine_dir_root
        File.join(root_dir, "test", "tmp", "pristinereps")
      end

      # One level up from the directory in which this repository's pristine version is stored
      def pristine_dir_parent
        if subpath.empty?
          pristine_dir_root
        else
          File.join pristine_dir_root, subpath
        end
      end

      # The directory in which this repository's pristine version is stored
      def pristine_dir
        File.join pristine_dir_parent, name
      end

      # builds/copies the test repository if needed
      def prepare
        #let's mark ourselves as dirty if any of our dependents are dirty
        if dependents.values.detect(&:'dirty?')
          mark_dirty
        end
        dependents.values.each {|child| child.prepare}

        if dirty?
          delete_clean_dir
        end

        #if the directory is there, we don't need to do anything
        if !File.exist?(clean_dir)
          Dir.chdir clean_dir_parent do
            mark_dirty
            if pristine_exists? && !pristine_dirty?
              copy_pristine_here
            else
              build_here
            end
            unmark_dirty

            copy_clean_to_pristine
          end
        end
      end

      def copy_clean_to_pristine
        if pristine_exists? && pristine_dirty?
          delete_pristine_dir
        end

        # if it exists, it's already done
        if !File.exist?(pristine_dir)
          pristine_mark_dirty
          Dir.chdir pristine_dir_parent do
            cp_a clean_dir, "."
          end
          pristine_unmark_dirty
        end
      end

      def copy_pristine_here
        cp_a pristine_dir, "."
      end

      def pristine_exists?
        File.exist?(pristine_dir)
      end

      def delete_clean_dir
        raise "hmmm... too scared to delete #{clean_dir}" unless clean_dir =~ /[\/\\]test[\/\\]tmp[\/\\]/
        rm_rf_ie clean_dir
      end

      def delete_pristine_dir
        raise "hmmm... too scared to delete #{pristine_dir}" unless clean_dir =~ /[\/\\]test[\/\\]tmp[\/\\]/
        rm_rf_ie pristine_dir
      end

      def dirty?
        Dir.chdir clean_dir_parent do
          File.exist?(working_file_name)
        end
      end

      def mark_dirty
        Dir.chdir clean_dir_parent do
          File.open working_file_name, "w" do |file|
            file.puts "dirty"
          end
        end
      end

      def unmark_dirty
        Dir.chdir clean_dir_parent do
          File.delete working_file_name
        end
      end

      def pristine_dirty?
        Dir.chdir pristine_dir_parent do
          File.exist?(working_file_name)
        end
      end

      def pristine_mark_dirty
        Dir.chdir pristine_dir_parent do
          File.open working_file_name, "w" do |file|
            file.puts "dirty"
          end
        end
      end

      def pristine_unmark_dirty
        Dir.chdir pristine_dir_parent do
          File.delete working_file_name
        end
      end

      def working_file_name
        ".working_#{name}"
      end
    end
  end
end
