require './asm.rb'

class CodeWriter

  def initialize
    @label = 0
  end

  # This function takes a "filename.vm" and extracts the basename, i.e. 
  # the filename without any extension, and also extracts the path.
  # It then constructs the name for the resulting .asm file,
  # by concatenating the basename and the path. 
  def set_file_name(filename) 
    # Raise an error if this is not a file
    raise ArgumentError, "Expected a file" unless File.file? filename 
    @fname = File.basename(filename, ".vm")
    @outfile = "#{File.dirname filename}/#{@fname}.asm"

    # This needs to be accessible to the assembler construction code,
    # so that we can create static variables.
    Asm.set_file_name(@fname)

    # Ensure that the output file does not already exist
    File.delete @outfile if File.exists? @outfile
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
    asm.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  # Given a vm stack operation, write the corresponding assembler instructions
  # to perform the push or pop operation.
  def write_pushpop(command, segment, value)
    asm = case command
          when :C_PUSH then Asm.push(segment, value)
          when :C_POP then Asm.pop(segment, value)
          else raise ArgumentError, "Unknown stack operation."
          end
    asm.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_label(name)
    asm = Asm.label(name) 
    asm.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_if_goto(name)
    asm = Asm.if_goto(name) 
    asm.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_goto(name)
    asm = Asm.goto(name) 
    asm.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_function_code(classname, functionname, numlocals)
    asm = Asm.function_code(classname, functionname, numlocals) 
    asm.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end

  def write_return
    asm = Asm.do_return
    asm.each {|a| File.write(@outfile, "#{a}\n", mode: "a")}
  end


end

