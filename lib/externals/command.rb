module Externals
  class Command
    attr_reader :name, :usage, :summary
    def initialize name, usage, summary = nil
      @name = name
      @usage = usage
      @summary = summary
      
      if !@summary
        @summary, @usage = @usage, @summary
      end
    end
    
    def to_s
      retval = StringIO.new
      retval.printf "%-16s", name
      if usage
        retval.printf "Usage: #{usage}\n"
      else
        dont_pad_first = true
      end
      
      summary.split(/\n/).each_with_index do |line, index|
        if index == 0 && dont_pad_first
          retval.printf "%s\n", line.strip
        else
          retval.printf "%16s%s\n", '', line.strip
        end
      end
      
      retval.printf "\n"
      retval.string
    end
  end
end
