require './code_writer.rb'

class Parser
  @writer 
  @data
  @current_cmd
  @type
  @words
  @arg1
  @arg2

  def initialize(stream, writer)  
    @filename = stream 
    @writer = writer
    @writer.set_file_name(stream)
    @data = File.open(stream)
  end

  def run
    until has_more_commands == false do 
      advance
      case command_type
      when :C_ARITHMETIC 
        @writer.write_arithmetic(@arg1)
      when :C_PUSH, :C_POP
        @writer.write_pushpop(@type, @arg1, @arg2)
      end
    end
  end

  def has_more_commands
    begin
      @words = @data.readline.split(/\s+/)
    rescue EOFError
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
    else
      @type = :C_UNKNOWN
    end
  end
      
end

code_writer = CodeWriter.new
stream = ARGV[0]
if File.directory?(stream)
  dir = stream
  Dir.children(dir).each do |fname| 
    next if File.extname(fname) != ".vm"  
    Parser.new("#{dir}/#{fname}", code_writer).run
 end
else
  puts "creating new parser for #{stream}"
  Parser.new(stream, code_writer).run
end
