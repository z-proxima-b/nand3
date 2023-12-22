module Asm

  @@segment2mnemonic = { "argument" => "ARG",
                         "local" => "LCL",
                         "this" => "THIS",
                         "that" => "THAT"}
                          

  @@label = 0
  @@returns = 0
  @@fname = ""

  def self.set_file_name(name)
    @@fname = name
  end

  def self.get_new_label
    @@label = @@label.next
  end

  def self.get_new_return_label
    @@returns = @@returns.next
  end

  def self.write_comment(type, *args)
    case type
    when :bootstrap
      ["// bootstrap"]
    when :arithmetic
      ["//#{args[0]}"]
    when :push
      ["// push #{args}"]
    when :pop
      ["// pop #{args}"]
    when :function
      ["// function #{args}"]
    end
  end

  def self.bootstrap
    asm = []
    asm << write_comment(:bootstrap, "SP")
    asm << ["@256", "D=A", "@SP", "M=D"]
    asm << write_comment(:bootstrap, "LCL")
    asm << ["@LCL", "M=-1"]
    asm << write_comment(:bootstrap, "ARG")
    asm << ["@ARG", "M=-1"]
    asm << write_comment(:bootstrap, "THIS")
    asm << ["@THIS", "M=-1"]
    asm << write_comment(:bootstrap, "THAT")
    asm << ["@THAT", "M=-1"]
    asm << write_comment(:call, "Sys.init")
    asm << function_call("Sys", "init", 0)
    asm.flatten
  end


  # write FALSE to the top of the stack
  def self.write_FALSE_to_stack
    ["@SP", "A=M", "M=0"]
  end
   
  # write TRUE to the top of the stack
  def self.write_TRUE_to_stack
    ["@SP", "A=M", "M=-1"]
  end
     
  # Return an array of assembler instructions for incrementing the stack
  # pointer. 
  def self.incrementSP
    ["@SP","M=M+1"]
  end

  # Return an array of assembler instructions for decrementing the stack
  # pointer, and then setting A to the resulting SP. 
  def self.decrementSP
    ["@SP","M=M-1"]
  end


  # Assembler instructions to push contents of register D to 
  # top of the stack. NB - will always increment the SP 
  def self.push_D_register_to_stack
    ["@SP", "A=M", "M=D", incrementSP].flatten
  end


  def self.copy_stack_top_to_D_register
    ["@SP", "A=M", "D=M"]
  end


  # Assembler instructions to pop stack top to 
  # D register. NB - will always decrement the SP
  def self.pop_stack_top_to_D_register
    [decrementSP, copy_stack_top_to_D_register].flatten
  end


  def self.store_constant_in_D_register(val)
    ["@#{val}", "D=A"] 
  end


  # Return assembler instruction to set A to the base address 
  # of a particular segment
  def self.store_base_address_in_A_register(segment)
    case segment 
      when "temp"
        "@R5"  
      when "pointer"
        "@THIS"
      else
        ["@#{@@segment2mnemonic[segment]}", "A=M"]   
    end
  end


  def self.calculate_seg_addr_and_store_in_A_register(seg, offs)
    if seg == "static" 
      ["@#{@@fname}.#{offs}"]
    else
      [store_constant_in_D_register(offs),
       store_base_address_in_A_register(seg), 
       "A=A+D"].flatten                          
    end
  end


  def self.read_from_segment_and_store_in_D_register(seg, offs)
    if seg == "constant"
      return ["@#{offs}", "D=A"].flatten
    else
      return [calculate_seg_addr_and_store_in_A_register(seg, offs),
              "D=M"].flatten
    end
  end


  def self.calculate_seg_addr_and_store_in_temp_var(seg, offs, varname)
    return [calculate_seg_addr_and_store_in_A_register(seg, offs),
            "D=A", "@#{varname}", "M=D"].flatten
  end


  def self.pop_stack_and_write_to_seg_addr(tempvar)
    [pop_stack_top_to_D_register,     # get first operand 
     "@#{tempvar}",                   # get ready to read saved addr 
     "A=M",                           # set A to saved address
     "M=D"]                           # store D in saved address 
  end


  def self.readable?(segment)
    readable_segments = ["argument", "local",   "this", "pointer", 
                         "that",     "static",  "temp"] 

    return true if readable_segments.include? segment 
    false
  end

  # Returns assembler instructions for pushing a value from a 
  # particular seg segment, onto the top of the stack. 
  # NB: Changes the Stack Pointer.
  def self.push(seg, offs)
    asm = []

    asm << write_comment(:push, seg, offs)

    if seg == 'constant'
      asm << [store_constant_in_D_register(offs)]
    else
      raise ArgumentError, "#{seg} is unreadable" unless readable? seg
      asm << [read_from_segment_and_store_in_D_register(seg, offs)] 
    end

    asm << [push_D_register_to_stack]
    asm.flatten
  end


  def self.writeable?(segment)
    writeable_segments = ["argument", "local",   "this", "pointer", 
                          "that",     "static",  "temp"] 

    return true if writeable_segments.include? segment 
    false
  end

  # Returns assembler instructions for popping a value from the 
  # the top of the stack, and writing it to a specific location
  # in the given seg segment.
  # NB: Changes the Stack Pointer.
  def self.pop(seg, offs)
    raise ArgumentError, "#{seg} is unwriteable" unless writeable? (seg)
    tempvar = "R13"
    asm = [
             write_comment(:pop, seg, offs),
             calculate_seg_addr_and_store_in_temp_var(seg, offs, tempvar),
             pop_stack_and_write_to_seg_addr(tempvar)
          ].flatten
  end
  
  def self.do_unary_op_and_push(cmd) 
    case cmd
    when :neg 
      ["M=-M"]
    when :not 
      ["M=!M"]
    else raise ArgumentError, "#{cmd} is not a unary op"
    end
  end 

  def self.comparison(truepathname, op, index)
    ["D=M-D",                        # D = *A-D 
     "@#{truepathname}#{index}", 
     "D; #{op}",                     # if comparison==true then jump 
     write_FALSE_to_stack,           # otherwise, push false to stack
     "@EXIT#{index}",      
     "0; JMP",                       # jump over the "true" branch 
     "(#{truepathname}#{index})",  # label for the "true" branch
     write_TRUE_to_stack,            # set to true
     "(EXIT#{index})"              # all branches lead here
    ]
  end

  def self.do_binary_op_and_push(cmd)
    case cmd
    when :add 
      ["M=M+D"]
    when :sub 
      ["M=M-D"]
    when :and 
      ["M=M&D"]
    when :or 
      ["M=M|D"]
    when :eq 
      comparison("EQUAL", "JEQ", get_new_label) 
    when :gt 
      comparison("GREATERTHAN", "JGT", get_new_label)
    when :lt 
      comparison("LESSTHAN", "JLT", get_new_label)
    end
  end 

  # Perform the given operation, on the stack's topmost TWO values.
  # Replace the two values with the (single value) result.
  def self.binary_op(type)
    [write_comment(:arithmetic, type),
     pop_stack_top_to_D_register,     # get first operand 
     decrementSP,                     # 
     "A=M",                           # prepare to examine second operand
     do_binary_op_and_push(type.to_sym), # do op and replace current top
     incrementSP]                     # restore the SP  
    .flatten                          # flatten to single layer and return 
  end


  # Perform the given operation, on the stack's topmost SINGLE value.
  # Replace the value with the result.
  def self.unary_op(type)
    [write_comment(:arithmetic, type),
     decrementSP,                       # 
     "A=M",                             # prepare to examine operand 
     do_unary_op_and_push(type.to_sym), # perform op and replace stack top 
     incrementSP]                       # restore the SP 
    .flatten                            # flatten to  single layer and return 
  end

  # Insert the given name as a label into the assembler command stream
  def self.label(name)
    ["(#{name})"].flatten
  end

  # Add assembler commands for examining the value at the top of the stack
  # and then jumping to the given label, if greater than zero
  def self.if_goto(name)
    [pop_stack_top_to_D_register,
     "@#{name}",
     "D; JGT"].flatten  
  end

  def self.goto(name)
    ["@#{name}",
     "0; JEQ"]
  end

  def self.function_code(classname, functionname, numlocals) 
    puts "#{classname} #{functionname} #{numlocals}"
    asm = []
    asm << [write_comment(:function, "entry point")]
    asm << ["(#{classname}.#{functionname})"] 
    asm << [write_comment(:function, "init locals")]
    asm << ["D=0", "@LCL", "A=M"]
    0.upto(numlocals.to_i-1) { 
      asm << [push_D_register_to_stack]
    }
    asm << [write_comment(:function, "finished init locals")] 
    asm.flatten
  end

  def self.function_return
    asm = []
    # FRAME = LCL - save FRAME in a temporary variable
    asm << [write_comment(:function, "save FRAME to a temp")] 
    asm << ["@LCL", "D=M", "@R13", "M=D"] 
    asm << [write_comment(:function, "save return addr to a temp")] 
    # RET = *(FRAME-5) - store return address in a temp var
    asm << ["@R13", "D=M", "@5", "A=D-A", "D=M", "@RET", "M=D"]   
    asm << [write_comment(:function, "put return value into *ARG")] 
    # *(ARG) = pop() - reposition the return value for the caller
    asm << [pop_stack_top_to_D_register, "@ARG", "A=M", "M=D"]  
    # SP = (ARG + 1)
    asm << [write_comment(:function, "set SP to ARG+1")] 
    asm << ["@ARG", "D=M", "D=D+1", "@SP", "M=D"]   
    # THAT = *(FRAME - 1)
    asm << [write_comment(:function, "set THAT to one above FRAME (LCL)")] 
    asm << ["@R13", "D=M", "@1", "A=D-A", "D=M", "@THAT", "M=D"]      
    # THIS = *(FRAME - 2)
    asm << [write_comment(:function, "set THIS to 2 above FRAME (LCL)")] 
    asm << ["@R13", "D=M", "@2", "A=D-A", "D=M", "@THIS", "M=D"]      
    # ARG = *(FRAME - 3)
    asm << [write_comment(:function, "set ARG to 3 above FRAME (LCL)")] 
    asm << ["@R13", "D=M", "@3", "A=D-A", "D=M", "@ARG", "M=D"]      
    # LCL = *(FRAME - 4)
    asm << [write_comment(:function, "set LCL to 4 above FRAME (LCL)")] 
    asm << ["@R13", "D=M", "@4", "A=D-A", "D=M", "@LCL", "M=D"]      
    # goto RET - go to return addr in caller's code
    asm << [write_comment(:function, "set JUMP to return address ")] 
    asm << ["@RET", "A=M", "0; JMP"]   
    asm.flatten
  end 

  def self.push_argument(n)
    [read_from_segment_and_store_in_D_register("argument", n),
     push_D_register_to_stack]
  end

  def self.push_base_address(segment)
     ["@#{@@segment2mnemonic[segment]}", "D=M",
      push_D_register_to_stack].flatten   
  end

  def self.reposition_ARG(nArgs)
    asm = []
    asm << ["@5", "D=A", "@nArgs", "D=D+A", "@R14", "M=D"]   
    asm << ["@ARG", "M=M-D"]  
    asm.flatten
  end

  def self.reposition_LCL
    ["@SP", "D=M", "@LCL", "M=D"]   
  end

  def self.jump_to_func(classname, funcname)
    ["@#{classname}.#{funcname}", "0; JMP"]
  end

  def self.function_call(classname, funcname, nArgs)
    asm = []
     
    # push nArgs to the stack
    asm << [write_comment(:function, "push nArgs (#{nArgs})")]
    0.upto(nArgs.to_i-1) { |n| asm << [push_argument(n)] }

    return_addr = "RETURN#{get_new_return_label}"

    # Push return address to the stack (stored in a named variable)
    asm << [write_comment(:function, "push return address (#{return_addr})")]
    asm << ["@#{return_addr}", "D=M", push_D_register_to_stack]
    asm << [write_comment(:function, "push LCL")]
    asm << [push_base_address("local")]
    asm << [write_comment(:function, "push ARG")]
    asm << [push_base_address("argument")]
    asm << [write_comment(:function, "push THIS")]
    asm << [push_base_address("this")]
    asm << [write_comment(:function, "push THAT")]
    asm << [push_base_address("that")]
    asm << [write_comment(:function, "reposition ARG")]
    #ARG = SP-n-5
    asm << [reposition_ARG(nArgs)]
    # LCL = SP
    asm << [reposition_LCL]
    # goto f
    asm << [jump_to_func(classname, funcname)]
    # declare a label for the return address 
    asm << ["(#{return_addr})"]
    asm.flatten
  end

end
