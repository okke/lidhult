
require_relative 'ImageBuilder.rb'

class ImageSet

  def initialize(s)
    @images = []
    @mapping = {}
    @space=s
  end

  def add(image) 
    @images << image
    @mapping[image.name] = image
  end

  def find(name)
    return @mapping[name]
  end

  def space
    return @space
  end

  def build_file_name
    if space
      return "images/build_#{space}.sh"
    else
      return "images/build.sh"
    end
  end

  def create
    # first create the images
    #
    @images.each do |i|
      i.create
    end

    # then, create the script that can build the actual images
    #
    File.open("#{build_file_name}", 'w') do |file|
      file.write "#!/bin/bash\n"
      @images.each do |i|
        file.write "docker build -t \"#{i.full_name}\" #{i.local_dir}\n"
      end
    end

    # and make sure its executable
    #
    File.chmod(0700, "#{build_file_name}")
  end

end

class ImageSetBuilder

  def initialize(space=nil, &block)
    @set = ImageSet.new(space)
    self.instance_eval &block
  end

  def image(name, &block)
    @set.add(build_image(name, @set, &block))
  end

  def image_set
    return @set 
  end

end


def build_image_set(space=nil, &block)
  return ImageSetBuilder.new(space, &block).image_set
end

def create_image_set(space=nil, &block)
  return build_image_set(space, &block).create
end
