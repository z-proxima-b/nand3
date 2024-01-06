require './asm.rb'

class CodeWriter

  def initialize(outfile, need_bootstrap)
    @label = 0
    puts "creating file... "

    begin
      File.delete(outfile)
    rescue Errno::ENOENT 
      puts "Ok, file #{outfile} does not already exist"
    end

    @outfile = File.new(outfile, "w")

    if need_bootstrap 
      write_bootstrap 
    end
  end

  def finalize
    p "closing file!!"
    @outfile.close
  end

  def set_scope(namespace)
    Asm.set_scope(namespace)
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
    asm.flatten.each {|a| @outfile.write("#{a}\n")}
  end

  # Given a vm stack operation, write the corresponding assembler instructions
  # to perform the push or pop operation.
  def write_pushpop(command, segment, value)
    asm = case command
          when :C_PUSH then Asm.push(segment, value)
          when :C_POP then Asm.pop(segment, value)
          else raise ArgumentError, "Unknown stack operation."
          end
    asm.flatten.each {|a| @outfile.write("#{a}\n")}
  end

  def write_label(name)
    asm = Asm.label(name) 
    asm.flatten.each {|a| @outfile.write("#{a}\n")}
  end

  def write_if_goto(name)
    asm = Asm.if_goto(name) 
    asm.flatten.each {|a| @outfile.write("#{a}\n")}
  end

  def write_goto(name)
    asm = Asm.goto(name) 
    asm.flatten.each {|a| @outfile.write("#{a}\n")}
  end

  def write_function_call(scope, func, nArgs)
    asm = Asm.function_call("#{scope}.#{func}", nArgs) 
    asm.flatten.each {|a| @outfile.write("#{a}\n")}
  end

  def write_function_code(scope, func, numlocals)
    asm = Asm.function_code("#{scope}.#{func}", numlocals) 
    asm.flatten.each {|a| @outfile.write("#{a}\n")}
  end

  def write_return
    asm = Asm.function_return
    asm.flatten.each {|a| 
      @outfile.write("#{a}\n")}
  end

  def write_bootstrap
    puts "writing bootstrap!"
    asm = Asm.bootstrap
    asm.each {|a|
      puts "writing: #{a}"
      @outfile.write("#{a}\n") }
  end
end

