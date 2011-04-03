class Array
  def to_hash
    @hash ||= self.inject({}){|r, c| r.merge!(c); r }
  end
end
