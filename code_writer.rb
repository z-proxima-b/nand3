require './asm.rb'

class CodeWriter

  def initialize
    @label = 0
  end

  # This function takes a dirname or a filename (single .vm file) 
  # Removes the ".vm" extension, if present. 
  # It then constructs the name for the resulting .asm file,
  # by concatenating the basename and the path. 
  def set_file_name(filename) 
    @outfile = "#{File.dirname filename}/#{File.basename(File.dirname filename)}.asm" if File.file? filename  
    @outfile = "#{filename}/#{File.basename filename}.asm" if File.directory? filename  
    puts @outfile

    # This needs to be accessible to the assembler construction code,
    # so that we can create static variables.
    Asm.set_file_name(@outfile)

    # Ensure that the output file does not already exist
    if File.exists? @outfile
      puts "#{@outfile} exists, so deleting"
    else
      puts "#{@outfile} does not exist."
    end
  end

  # Given a vm asm.arithmetic command, write the corresponding
  # assembler instructions to the output file.
  def write_arithmetic(cmd)
    asm = case cmd 
      when "add", "sub", "eq", "gt", "lt", 
           "or",  "and" 
        Asm.binary_op(cmd)
      when "neg", "not"
        Asm.unary_op(cmd)
      else
        raise ArgumentError, "Unknown arithmetic command #{cmd}." 
    end
    asm.flatten.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}

  end

  # Given a vm stack operation, write the corresponding assembler instructions
  # to perform the push or pop operation.
  def write_pushpop(command, segment, value)
     asm = case command
          when :C_PUSH then Asm.push(segment, value)
          when :C_POP then Asm.pop(segment, value)
          else raise ArgumentError, "Unknown stack operation."
          end
    asm.flatten.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_label(name)
    asm = Asm.label(name) 
    asm.flatten.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_if_goto(name)
    asm = Asm.if_goto(name) 
    asm.flatten.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_goto(name)
    asm = Asm.goto(name) 
    asm.flatten.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_function_call(scope, func, nArgs)
    asm = Asm.function_call("#{scope}.#{func}", nArgs) 
    asm.flatten.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_function_code(scope, func, numlocals)
    asm = Asm.function_code("#{scope}.#{func}", numlocals) 
    asm.flatten.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_return
    asm = Asm.function_return
    asm.flatten.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_bootstrap
    asm = Asm.bootstrap
    puts "empty bootstrap" if asm.empty?
    puts "size: #{asm.length}" 
    asm.each {|a|
      puts "writing #{a}"
      File.write(@outfile, "#{a}\n", mode: "a")}
  end
end

