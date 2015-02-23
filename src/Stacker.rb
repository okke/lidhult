
require_relative 'ImageSetBuilder.rb'


class StackerDefinition

  def initialize()
    @sets = []
  end

  def add_set(set)
    @sets << set
  end


  def create
    @sets.each do |s|
      s.create
    end
  end

end

class StackerDefinitionBuilder

  def initialize(ruby_def)
    @def = StackerDefinition.new()
    eval ruby_def, binding
  end

  def image_set(space=nil, &block)
    @def.add_set(build_image_set(space,&block))
  end

  def definition
    return @def
  end

end

class Stacker
  
  def initialize(ruby_def)
    verbose "initialize stacker"
    @def = StackerDefinitionBuilder.new(ruby_def).definition
  end


  def create
    @def.create
  end
end

