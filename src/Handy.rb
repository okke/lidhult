
# copied (and modified) from active_support
#
# Add a strip_heredoc method to string to support inline textblocks in builder dsl's
#
class String
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      __send__(*a, &b)
    end
  end

  def strip_heredoc
    indent = scan(/^[ \t]*(?=\S)/).min
    if(indent)
      indent = indent.try(:size)
    else 
      indent = 0
    end
    gsub(/^[ \t]{#{indent}}/, '')
  end
end

# Utility class that can be used to build hashes 
# using an instance_eval construction
#
class HashBuilder

  def initialize(env)
    @own_mapping = {}
    @given_mapping = env
  end

  def method_missing(method_sym, *arguments, &block)
    if arguments.size == 0

      # probably a lookup. First look in own map
      #
      if @own_mapping.has_key? method_sym
        return @own_mapping[method_sym]
      end

      # not found, look up in given map
      # 
      if @given_mapping.has_key? method_sym
        return @given_mapping[method_sym]
      end

    end

    value = arguments.first
    value = "true" if not arguments.first

    @own_mapping[method_sym] = value
  end

  def hash
    return @own_mapping
  end

end


#
# Utility class that can be used to build lines of text
# using an instance_eval construction
#
class TextBuilder

  def initialize()
    @text = []
  end

  def method_missing(method_sym, *arguments, &block)
    if arguments.size == 0
      raise NoMethodError.new(method_sym.to_s)
    else
      line = [method_sym.to_s]
      arguments.each do |arg|
        if arg.is_a?(String) and arg.index(" ")
          arg = "\"#{arg}\""
        end
        
        line << arg.to_s
      end
      text << line.join(" ")
    end
  end

  def text
    return @text
  end

end


if not defined? RT_OPTIONS
  RT_OPTIONS = {} 
end

def verbose(s)
  if RT_OPTIONS[:verbose]
    RT_OPTIONS[:verbose].call s
  end
end
