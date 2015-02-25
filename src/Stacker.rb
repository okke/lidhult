# 
# Copyright (c) 2015, Okke van 't Verlaat
#  
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 

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

