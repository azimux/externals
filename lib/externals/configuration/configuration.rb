module Externals
  module Configuration
    SECTION_TITLE_REGEX_NO_GROUPS = /^\s*\[(?:[^\]]*)\]\s*$/
    SECTION_TITLE_REGEX = /^\s*\[([^\]]*)\]\s*$/


    class Section
      attr_accessor :title_string, :body_string, :title, :rows

      def initialize title_string, body_string
        self.title_string = title_string
        self.body_string = body_string

        self.title = SECTION_TITLE_REGEX.match(title_string)[1]

        raise "Invalid section title: #{title_string}" unless title

        self.rows = body_string.strip.split(/\n/)
      end


      SETTING_REGEX = /^\s*([\.\w-]+)\s*=\s*([^#\n]*)(?:#[^\n]*)?$/
      SET_SETTING_REGEX = /^(\s*(?:[\.\w-]+)\s*=\s*)(?:[^#\n]*)(#[^\n]*)?$/

      def attributes
        retval = {}
        rows.each do |row|
          if row =~ SETTING_REGEX
            retval[$1.strip] = $2.strip
          end
        end
        retval
      end
      def setting key
        rows.each do |row|
          if row =~ SETTING_REGEX && key.to_s == $1
            return $2.strip
          end
        end
        nil
      end
      def set_setting key, value
        key = key.to_s
        found = nil

        rows.each_with_index do |row, index|
          if row =~ SETTING_REGEX && key == $1
            raise "found #{key} twice!" if found
            found = index
          end
        end

        if found
          if rows[found] !~ SET_SETTING_REGEX
            raise "thought I found the row, but didn't"
          end
          rows[found] = "#{$1}#{value}#{$2}"
        else
          rows << "#{key} = #{value}"
        end
        value
      end

      def rm_setting key
        key = key.to_s
        found = nil
        value = nil

        rows.each_with_index do |row, index|
          if row =~ SETTING_REGEX && key == $1
            raise "found #{key} twice!" if found
            found = index
          end
        end

        if found
          value = self[key]
          if rows[found] !~ SET_SETTING_REGEX
            raise "thought I found the row, but didn't"
          end
          rows.delete rows[found]
        end
        value
      end

      def [] key
        setting(key)
      end
      def []= key, value
        set_setting(key, value)
      end

      def add_row(row)
        rows << row

        self.body_string = body_string.chomp + "\n#{row}\n"
        #clear_caches
      end

      def to_s
        "[#{title}]\n#{rows.join("\n")}"
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

      def []= title, hash
        add_empty_section title
        section = self[title]
        hash.each_pair do |key,value|
          section[key] = value
        end
      end

      def remove_section sec
        sec = sections.detect{|section| section.title == sec}

        raise "No section found in config file for #{sec}" unless sec
        sections.delete(sec)
      end

      def add_empty_section  title
        raise "Section already exists" if self[title]
        sections << Section.new("[#{title.to_s}]", "")
      end

      def removed_project_paths other_config
        all_paths - other_config.all_paths
      end

      def all_paths
        sections.map(&:title)
      end

      def self.new_empty
        new nil, true
      end

      def initialize file_string = nil, empty = false
        self.file_string = file_string

        return if empty
        raise "I was given no file_string" unless file_string

        titles = []
        file_string.each_line {|line| titles << line if line =~ SECTION_TITLE_REGEX}
        bodies = file_string.split SECTION_TITLE_REGEX_NO_GROUPS

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

      def write path = ".externals"
        raise "no path given" unless path
        open(path, 'w') do |f|
          f.write to_s
        end
      end

      def to_s
        sections.map(&:to_s).join("\n\n")
      end
    end
  end
end
