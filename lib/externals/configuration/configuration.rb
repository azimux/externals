module Externals
  module Configuration
    SECTION_TITLE_REGEX = /^\s*\[(\w+)\]\s*$/
    SECTION_TITLE_REGEX_NO_GROUPS = /^\s*\[(?:\w+)\]\s*$/


    class Section
      attr_accessor :title_string, :body_string, :title, :rows, :scm

      def main?
        title == 'main'
      end

      def initialize title_string, body_string, scm = nil
        self.title_string = title_string
        self.body_string = body_string
        self.scm = scm

        self.title = SECTION_TITLE_REGEX.match(title_string)[1]
        
        self.scm ||= self.title

        raise "Invalid section title: #{title_string}" unless title

        self.rows = body_string.split(/\n/)
      end

      def setting key
        if !main?
          raise "this isn't a section of the configuration that can contain settings"
        end

        rows.each do |row|
          if row =~ /\s*(\w+)\s*=\s*([^#\n]*)(?:#[^\n])?$/ && key.to_s == $1
            return $2.strip
          end
        end
        nil
      end

      def [] key
        setting(key)
      end


      def projects
        return @projects if @projects

        @projects = []

        if main?
          @projects = [Ext.project_class(self['scm']).new(".", :is_main)]
        else
          rows.each do |row|
            if Project.project_line?(row)
              @projects << Ext.project_class(title).new(row)
            end
          end
          @projects
        end
      end

      def add_row(row)
        rows << row

        self.body_string = body_string.chomp + "\n#{row}\n"
        clear_caches
      end

      def clear_caches
        @projects = nil
      end

      def to_s
        "#{title_string}#{body_string}"
      end
    end

    class Configuration
      attr_accessor :file_string

      def sections
        @sections ||= []
      end

      def [] title
        title = title.to_s
        sections.detect {|section| section.title == title}
      end
      
      def add_empty_section  title
        raise "Section already exists" if self[title]
        sections << Section.new("\n\n[#{title.to_s}]\n", "")
      end
      
      def self.new_empty
        new nil, true
      end

      def initialize externals_file = nil, empty = false
        if empty
          self.file_string = ''
          return
        end
        
        if !externals_file && File.exists?('.externals')
          open('.externals', 'r') do |f|
            externals_file = f.read
          end
        end

        externals_file ||= ""

        self.file_string = externals_file

        titles = externals_file.grep SECTION_TITLE_REGEX
        bodies = externals_file.split SECTION_TITLE_REGEX_NO_GROUPS

        if titles.size > 0 && bodies.size > 0
          if titles.size + 1 != bodies.size
            raise "bodies and sections do not match up"
          end

          bodies = bodies[1..(bodies.size - 1)]

          (0...(bodies.size)).each do |index|
            sections << Section.new(titles[index], bodies[index])
          end
        end
      end

      def projects
        retval = []
        sections.each do |section|
          retval += section.projects
        end

        retval
      end

      def subprojects
        retval = []
        sections.each do |section|
          retval += section.projects unless section.main?
        end

        retval
      end

      def write path = ".externals"
        open(path, 'w') do |f|
          sections.each do |section|
            f.write section.to_s
          end
        end
      end
    end
  end
end