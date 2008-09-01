String.class_eval do
  def cap_first
    "#{self[0].chr.upcase}#{self[1..(self.length - 1)]}"
  end
  
  def classify
    split('_').map(&:cap_first).join
  end
end