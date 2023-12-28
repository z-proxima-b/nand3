module Asm

  @@segment2mnemonic = { "argument" => "ARG",
                         "local" => "LCL",
                         "this" => "THIS",
                         "that" => "THAT"}
                          

  @@label = 0
  @@returns = 0
  @@fname = ""
  @@asm = []

  def self.set_file_name(name)
    @@fname = name
  end

  def self.get_new_label
    @@label = @@label.next
  end

  def self.next_return_label
    @@returns = @@returns.next
  end

  def self.comment(*args)
    ["// #{args}"]
  end
  
  def write_(code, type=:REGULAR)
    case type
      when :COMMENT
			@@asm << ["// #{code}"]
      when :LABEL
			@@asm << ["(", "#{code}"]
	  when :REGULAR
            @@asm << ["\t", "#{code.flatten.join('\n')}"]
      end 

    case type
      when :LABEL
			@@asm << [")"]
      when :REGULAR
			@@asm << ["\t\t\t\t\t"]
      end 

	@@asm << ["\n"]
  end


  def self.bootstrap
    write_("SP=256", :COMMENT)
    write_(["@256", "D=A", "@0", "M=D"])
    write_("Call Sys.init", :COMMENT)
	write_function_call("Sys.init", 0)
  end


  # write FALSE to the top of the stack
  def self.write_FALSE_to_stack
    write_("@SP", "A=M", "M=0")
  end
  

  # write TRUE to the top of the stack
  def self.write_TRUE_to_stack
    write_("@SP", "A=M", "M=-1")
  end


  def self.copy_stack_top_to_D_register
    ["@SP", "A=M", "D=M"]
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
    write_("@SP", "A=M", "M=D", incrementSP)
  end

  # Assembler instructions to pop stack top to 
  # D register. NB - will always decrement the SP
  def self.pop_stack_top_to_D_register
    [decrementSP, copy_stack_top_to_D_register]
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
    write_("push #{seg} #{offs}", :COMMENT)
    
    if seg == 'constant'
      write_([store_constant_in_D_register(offs)])
    else
      raise ArgumentError, "#{seg} is unreadable" unless readable? seg
      write_([read_from_segment_and_store_in_D_register(seg, offs)]) 
    end

    write_([push_D_register_to_stack])
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
    write_("pop #{seg} #{offs}", :COMMENT)
    tempvar = "R13"
    write_([calculate_seg_addr_and_store_in_temp_var(seg, offs, tempvar),
              [pop_stack_and_write_to_seg_addr(tempvar)])
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
    [comment(:arithmetic, type),
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
    [comment(:arithmetic, type),
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
    asm << [comment(:function, "entry point")]
    asm << ["(#{classname}.#{functionname})"] 
    asm << [comment(:function, "init locals")]
    asm << ["D=0", "@LCL", "A=M"]
    0.upto(numlocals.to_i-1) { 
      asm << [push_D_register_to_stack]
    }
    asm << [comment(:function, "finished init locals")] 
    asm.flatten
  end

  def self.function_return
    # FRAME = LCL - save FRAME in a temporary variable
    write_("save FRAME to a temp", :COMMENT] 
    ["@LCL", "D=M", "@R13", "M=D"] 
    write_("RET = *(FRAME)", :COMMENT) 
    write_("@R13", "D=M", "@5", "A=D-A", "D=M", "@RET", "M=D")   
    write_("*(ARG) = pop() - reposition the return value") 
    write_(pop_stack_top_to_D_register, "@ARG", "A=M", "M=D")  
    write_("set SP to ARG+1") 
    write_("@ARG", "D=M", "D=D+1", "@SP", "M=D")   
    # THAT = *(FRAME - 1)
    asm << [comment(:function, "set THAT to one above FRAME (LCL)")] 
    asm << ["@R13", "D=M", "@1", "A=D-A", "D=M", "@THAT", "M=D"]      
    # THIS = *(FRAME - 2)
    asm << [comment(:function, "set THIS to 2 above FRAME (LCL)")] 
    asm << ["@R13", "D=M", "@2", "A=D-A", "D=M", "@THIS", "M=D"]      
    # ARG = *(FRAME - 3)
    asm << [comment(:function, "set ARG to 3 above FRAME (LCL)")] 
    asm << ["@R13", "D=M", "@3", "A=D-A", "D=M", "@ARG", "M=D"]      
    # LCL = *(FRAME - 4)
    asm << [comment(:function, "set LCL to 4 above FRAME (LCL)")] 
    asm << ["@R13", "D=M", "@4", "A=D-A", "D=M", "@LCL", "M=D"]      
    # goto RET - go to return addr in caller's code
    asm << [comment(:function, "set JUMP to return address ")] 
    asm << ["@RET", "A=M", "0; JMP"]   
    asm.flatten
  end 

  def self.asm_for_push_argument_(n)
    [read_from_segment_and_store_in_D_register("argument", n),
     push_D_register_to_stack]
  end

  def self.asm_for_push_base_address_(segment)
     ["@#{@@segment2mnemonic[segment]}",
      "D=M",
      push_D_register_to_stack]
  end

  def self.write_asm_for_repositioning_ARG(nArgs)
    write_("reposition ARG", :COMMENT) 
    write_(["@5", "D=A", "@nArgs", "D=D+A", "@R14", "M=D"])   
    write_(["@ARG", "M=M-D"])  
  end

  def self.write_asm_for_repositioning_LCL
    write_("reposition LCL", :COMMENT) 
    write_(["@SP", "D=M", "@LCL", "M=D"])   
  end

  def self.write_asm_for_jump_to_func(funcname)
    write_("jump to #{funcname}", :COMMENT) 
    write_(["@#{funcname}", "0; JMP"])
  end

  def asm_for_push_return_address_(addr)
     ["@#{addr}",
     "D=M",
     push_D_register_to_stack]
  end

  def self.write_asm_for_stack_frame_(returnaddr)
    write_("save stack frame", :COMMENT) 
    write_("save return address", :COMMENT) 
    write_(asm_for_push_return_address_(returnaddr))
    write_("save LCL", :COMMENT) 
    write_(asm_for_push_base_address_("LCL"))
    write_("save ARG", :COMMENT) 
    write_(asm_for_push_base_address_("ARG"))
    write_("save THIS", :COMMENT) 
    write_(asm_for_push_base_address_("THIS"))
    write_("save THAT", :COMMENT) 
    write_(asm_for_push_base_address_("THAT"))
  end

  def self.write_asm_for_push_nargs_(nArgs)
    write_("push nArgs #{nArgs}", :COMMENT) 
    0.upto(nArgs.to_i-1) {|n|
      write_(push_argument(n))
    }
  end

  def self.function_call(funcname, nArgs)
    # push nArguments to the stack 
    write_asm_for_push_nargs_(nArgs))

    # save the stack frame, for restoring state later 
    return_addr = "RETURN#{next_return_label}"
    write_asm_for_stack_frame_(return_addr))

    # prepare ARG and LCL base addresses  
    write_asm_for_repositioning_ARG(nArgs)
    write_asm_for_repositioning_LCL
  
    # jump to the function
    write_asm_for_jump_to_func(funcname)
    
    # we are handling the "call f" vm command,
    # so the asm command after this sequence is where we 
    # want to return. 
    # So label it, in the asm.
    write_("#{return_addr}", :LABEL)
  end

end
