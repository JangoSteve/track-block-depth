class MyObject
  
  def block_depth=(value)
    Thread.current[:block_depth] = value
  end
  
  def block_depth
    Thread.current[:block_depth] || 0
  end
  
  def track_block_depth(&block)
    self.block_depth += 1
    yield
    ensure
      self.block_depth -= 1
  end
  
  def method1(stuff, &block)
    puts "This is #{stuff}... #{self.block_depth} level deep\n"
    yield
  end
  
  def method2(stuff, &block)
    puts "This is #{stuff}... #{self.block_depth} levels deep\n"
    yield
  end
  
  def method_missing(method_name,*args, &block)
    if method_name.to_s =~ /([\w\d]+)_with_block_depth/ && self.respond_to?($1)
      self.class.send :define_method, method_name do |*args, &block|
        self.track_block_depth do
          self.send($1, *args, &block)
        end
      end
      self.send(method_name, *args, &block)
    else
      super
    end
  end
  
  def respond_to?(method_name, include_private = false)
    if method_name.to_s =~ /([\w\d]+)_with_block_depth/ && self.respond_to?($1)
      true
    else
      super
    end
  end

end

obj = MyObject.new

t1 = Thread.new do
  obj.method1_with_block_depth "something" do
    obj.method2_with_block_depth "something else" do
      puts "hiya\n"
    end
    puts "Back to #{obj.block_depth} level deep\n"
  end
end

t2 = Thread.new do
  obj.method1_with_block_depth "something" do
    obj.method2_with_block_depth "something else" do
      puts "hiya\n"
    end
    puts "Back to #{obj.block_depth} level deep\n"
  end
end

t3 = Thread.new do
  obj.method1 "something" do
    obj.method2 "something else" do
      puts "hiya\n"
    end
    puts "Back to #{obj.block_depth} level deep\n"
  end
end

t1.join
t2.join
t3.join

# => This is something... 1 level deep
# => This is something... 1 level deep
# => This is something else... 2 levels deep
# => This is something else... 2 levels deep
# => hiya
# => hiya
# => Back to 1 level deep
# => Back to 1 level deep