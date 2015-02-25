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

require_relative './Handy.rb'

require 'fileutils'

class FromInstruction 
  
  def initialize(f)
    @from = f
  end

  def create(file)
    file.write "FROM #{@from}\n"
    return self
  end
end

class RunInstruction 
  
  def initialize(cmd)
    @cmd = cmd
  end

  def create(file)
    file.write "RUN #{@cmd}\n"
    return self
  end
end

class CopyInstruction 
  
  def initialize(dir, fname, content)
    @dir = dir
    @fname = fname
    @content = content
  end

  def create(file)

    local_fname = ""
    image_fname = ""
    if @fname[0] == '/'
      local_fname = "#{@dir}#{@fname}" 
      image_fname = ".#{@fname}" 
    else
      local_fname = "#{@dir}/#{@fname}"
      image_fname = "#{@fname}"
    end

    local_path = File.dirname(local_fname)

    if not File.exists?(local_path)
      FileUtils.mkpath local_path 
    end

    file.write "COPY #{image_fname} #{@fname}\n"

    File.open(local_fname, 'w') do |local_file|
      local_file.write @content
    end
  end
end

class EnvInstruction 
  
  def initialize(key, value)
    @key = key
    @value = value
  end

  def create(file)
    file.write "ENV #{@key}=\"#{@value}\"\n"
  end
end

class EntryPointInstruction 
  
  def initialize(cmd)
    @cmd = cmd
  end

  def create(file)
    file.write "ENTRYPOINT #{@cmd}\n"
    return self
  end
end


class Image 

  def initialize(name, builder)
    @name = name
    @builder = builder
    @instructions = []
  end
  
  def build_by
    return @builder
  end

  def name
    return @name
  end

  def full_name
    if build_by and build_by.set and build_by.set.space
      return "#{build_by.set.space}/#{@name}"
    else
      return "#{@name}"
    end
  end

  def local_dir
    if build_by and build_by.set and build_by.set.space
      return "images/#{build_by.set.space}/#{@name}"
    else
      return "images/#{@name}"
    end
  end
 
  def create

    unless File.directory?(local_dir)
      FileUtils.mkdir_p(local_dir)
    end

    File.open("#{local_dir}/Dockerfile", 'w') do |file|
      @instructions.each do |i|
        i.create file
      end
    end

  end

  def from(space=nil, f)
    name = f
    name = "#{space}/#{f}" if space
    @instructions << FromInstruction.new(name)
  end

  def run(cmd)
    @instructions << RunInstruction.new(cmd)
  end

  def file(fname, content)
    @instructions << CopyInstruction.new(local_dir, fname, content)
  end

  def env(key, value)
    @instructions << EnvInstruction.new(key,value)
  end

  def entrypoint(cmd)
    @instructions << EntryPointInstruction.new(cmd)
  end
end

class ImageBuilder

  def initialize(name, set=nil, &block)
    @set = set
    @image = Image.new(name, self)
    @env = {}
    @parent = nil
    self.instance_eval &block
  end

  def method_missing(method_sym, *arguments, &block)
    if arguments.size == 0
      result = env_var(method_sym)
      return result if result

      if @parent
        result = @parent.build_by.env_var(method_sym)
        return result if result
      end
    end

    raise NoMethodError.new(method_sym.to_s)
  end

  def env_var(sym)
    return @env[sym] 
  end

  def image
    return @image
  end

  def set
    return @set
  end

  def from(f)

    if set and f.class == Symbol
      image.from(set.space,f)
    else
      image.from f
    end

    # when an image is part of an image set, it should be able to
    # access its parents environment if this parent is part of
    # the same set
    #
    if set
      @parent = set.find(f)
    end
  end

  def run(cmd=nil, &block)
    if block
      builder = TextBuilder.new
      builder.instance_eval &block
      builder.text.each do |line|
          image.run line
      end
    else
      if cmd
        cmd.strip_heredoc.split("\n").each do |line|
          image.run line
        end
      end
    end
  end

  def file(fname, content)
    image.file fname, content.strip_heredoc
  end

  def entrypoint(cmd)
    image.entrypoint cmd
  end

  def start(fname, content)
    file fname, content.strip_heredoc
    run "chmod +x #{fname}"
    entrypoint "exec #{fname}"
  end

  def env(&block)
    builder = HashBuilder.new(@env)
    builder.instance_eval &block
    builder.hash.each do |k,v| 

      @env[k] = v

      # env vars starting with an underscore are hidden
      #
      if k[0] == '_'
        # env vars starting with a double underscore are not hidden
        # but the first underscore will be ignored
        #
        if k.length > 1 and k[1] == '_'
          image.env k[1..-1],v
        end
      else 
        image.env k,v
      end
    end
  end

end

def build_image(name, set=nil, &block)
  return ImageBuilder.new(name, set, &block).image
end


def create_image(name, &block)
  return build_image(name, &block).create
end


