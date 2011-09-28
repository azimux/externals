String.class_eval do
  def cap_first
    "#{self[0].chr.upcase}#{self[1..(self.length - 1)]}"
  end

  def classify
    split('_').map(&:cap_first).join
  end

  #avoid collision
  raise unless instance_methods.include?("lines")
  raise if instance_methods.include?("lines_by_width")
  def lines_by_width(width = 32)
    width ||= 32
    lines = []
    string = gsub(/\s+/, ' ')
    while string.size > 0
      if string.size <= width
        lines << string
        string = ""
      else
        index = string[0, width + 1].rindex(/\s/)
        unless index
          # let's find the first space we can.
          index = string.index(/\s/)
        end
        if index
          lines << string[0, index]
          string = string[(index + 1)..-1]
        else
          lines << string
          string = ""
        end
      end
    end

    lines
  end
end