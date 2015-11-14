class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method "#{name}=" do |x|
        instance_variable_set("@#{name.to_s}", x)
      end
    end

    names.each do |name|
      define_method "#{name}" do
        instance_variable_get("@#{name.to_s}".to_sym)
      end
    end
  end
end
