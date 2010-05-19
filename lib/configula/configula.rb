class Configula
  
  def initialize(children_hash={})
    put(children_hash)
  end
  
  def method_missing(method_name, *return_val)
    set method_name, return_val[0]
  end
  
  def set(child, value)
    Configula.wire_up self, child, value
  end  
    
  def put(children_hash)
    children_hash.keys.each{ |k| self.send("#{k.to_s}=", children_hash[k]) }
  end
  
  def [](field)
    self.send(field)
  end
  
  def self.add_children(parent, children_hash)
    children_hash.keys.each{ |k| parent.send("#{k.to_s}=", children_hash[k]) }
  end
  
  @@locked = false
  
  def self.locked?
    @@locked
  end
  
  def self.lock
    @@locked = true
  end
  
  def self.unlock
    @@locked = false
  end
  
  def self.wire_up(obj, method_name, return_val)
    
    if(@@locked)
      if( return_val.nil? )
        return nil
      else
        e = StandardError.new("config locked")
        p e.backtrace
        raise e
      end
    end
    
    return_val = return_val.to_s if return_val.class == Fixnum
    
    method_name = method_name.to_s
    method_is_assignment = method_name[-1,1] == "="
    cached_ret_val = return_val
    
    # if method is NOT an assignment 
    # then its either a "pass through accessor" or were setting children with a hash
    # so, return_val is a hash then...
    if(! method_is_assignment )
      
      if( return_val.nil?)
        # if ret val is nil, we just an accessor, and need to create it
        # this is likely because of setting a child like this:
        # x.y.z=something   where x.y doesnt exist yet
        return_val = Configula.new
      elsif( return_val.class==Hash )
        return_val = Configula.new
      end
      
      method_name << "="
    end
    
    eval(<<-EOS
      def obj.#{method_name.chop}(children={});  
        Configula.add_children(@#{method_name.chop}, children);  
        ret_val = @#{method_name.chop};
        ret_val.kind_of?(Proc) ? ret_val.call : ret_val;
      end
    EOS
    )
    
    eval("def obj.put(children={});  Configula.add_children(self, children); end")
    eval("def obj.set_#{method_name}(p); @#{method_name.chop} =  p; end")
    
    obj.send("set_#{method_name}", return_val)
    
    unless return_val.nil?
      def return_val.method_missing(nm, *rv)
        Configula.wire_up self, nm, rv[0]  
      end
    end
    
    # if we are setting childen on a value that doesnt exist using a hash...
    if( ! method_is_assignment && cached_ret_val.class==Hash )
      obj.send(method_name.chop, cached_ret_val)
    end

    return_val
  end
  
end
