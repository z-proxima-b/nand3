require './code_writer.rb'

class Parser
  @writer 
  @data
  @current_cmd
  @type
  @words
  @arg1
  @arg2
  @arg3

  def initialize(writer)  
    @writer = writer
  end

  def run(fname)
    puts "parser working on vm file: #{fname}"
    @data = File.open(fname)
    
    @writer.set_scope(File.basename(fname))

    until has_more_commands == false do 
      advance
      #puts "command type #{command_type}"
      case command_type
      when :C_ARITHMETIC 
        @writer.write_arithmetic(@arg1)
      when :C_PUSH, :C_POP
        @writer.write_pushpop(@type, @arg1, @arg2)
      when :C_GOTO
        @writer.write_goto(@arg1)
      when :C_IF_GOTO
        @writer.write_if_goto(@arg1)
      when :C_LABEL
        @writer.write_label(@arg1)
      when :C_FUNCTION 
        @writer.write_function_code(@arg1, @arg2, @arg3)
      when :C_CALL
        @writer.write_function_call(@arg1, @arg2, @arg3) 
      when :C_RETURN
        @writer.write_return
      end
    end
  end

  def has_more_commands
    begin
      @words = @data.readline.scan(/[\/\w-]+/)
      p @words
    rescue ArgumentError, EOFError
      return false
    end
    true
  end

  def advance
    parse_(@words)
  end

  def command_type
    return @type 
  end

  def arg1
    return @arg1
  end

  def arg2
    return @arg2
  end

  def parse_(words)
    case words[0]
    when "//"
      @type = :C_COMMENT
    when "add","sub","neg","eq","gt","lt","and","or","not"
      @type = :C_ARITHMETIC
      @arg1 = words[0]
    when "push"
      @type = :C_PUSH
      @arg1 = words[1]
      @arg2 = words[2]
    when "pop"
      @type = :C_POP
      @arg1 = words[1]
      @arg2 = words[2]
    when "goto"
      @type = :C_GOTO
      @arg1 = words[1]
    when "if-goto"
      @type = :C_IF_GOTO
      @arg1 = words[1]
    when "label"
      @type = :C_LABEL
      @arg1 = words[1]
    when "function"
      @type = :C_FUNCTION
      @arg1 = words[1]
      @arg2 = words[2]
      @arg3 = words[3]
    when "call"
      @type = :C_CALL
      @arg1 = words[1]
      @arg2 = words[2]
      @arg3 = words[3]
    when "return"
      @type = :C_RETURN
    else
      @type = :C_UNKNOWN
    end
  end
      
end

stream = ARGV[0]
puts "The first arg = #{stream}"

directoryname = ""
outfilename = ""
to_parse = []

########################################################################
if File.directory?(stream)
  directoryname = stream
  to_parse = Dir.glob("*.vm", base: "#{stream}") 
else
  directoryname = File.dirname stream
  to_parse = [File.basename(stream)] 
end

puts "directory = #{directoryname}"
puts "filename = #{File.basename(directoryname)}"
outfilename = "#{directoryname}//#{File.basename(directoryname)}.asm" 

need_bootstrap = to_parse.length>1
code_writer = CodeWriter.new(outfilename, need_bootstrap)
parser = Parser.new(code_writer)
puts "need bootstrap? #{need_bootstrap}"
to_parse.each {|f| parser.run("#{directoryname}//#{f}") }

