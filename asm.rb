module Asm

  @@segment2mnemonic = { "argument" => "ARG",
                         "local" => "LCL",
                         "this" => "THIS",
                         "that" => "THAT"}
  
  @@label = 0
  @@returns = 0
  @@scope = ""


  ##########################################################################
  # Perform the given operation, on the stack's topmost TWO values.
  # Replace the two values with the (single value) result.
  def self.binary_op(type)
   
    instr = []
    instr << comment_("binary op")
    instr << [pop_stack_top_to_D_register,    # get first operand 
            decrementSP,                     # 
            "A=M",                           # prepare to examine second operand
            op_and_push(type.to_sym),        # do op and replace current top
            incrementSP]
    format_(instr)                           # restore the SP  
    
  end
    


  ##########################################################################
  # Perform the given operation, on the stack's topmost SINGLE value.
  # Replace the value with the result.
  def self.unary_op(type)
    
    instr = []
    instr << comment_("unary op #{type}")
    instr << [decrementSP, "A=M",        # prepare to examine operand 
             op_and_push(type.to_sym),  # perform op and replace stack top 
             incrementSP]               # restore the SP 
    format_(instr)
    
  end


  ##########################################################################
  # Returns assembler instructions for pushing a value from a 
  # particular seg segment, onto the top of the stack. 
  # NB: Changes the Stack Pointer.
  def self.push(seg, offs)
    instr = [ comment_("push #{seg} #{offs}")]
   
    if seg == 'constant'
      instr << [store_constant_in_D_register(offs)]
    else
      raise ArgumentError, "#{seg} is unreadable" unless readable? seg
      instr << [read_from_segment_and_store_in_D_register(seg, offs)] 
    end
    instr << push_D_register_to_stack

    format_(instr)
    
  end


  ##########################################################################
  # Returns assembler instructions for popping a value from the 
  # the top of the stack, and writing it to a specific location
  # in the given seg segment.
  # NB: Changes the Stack Pointer.
  def self.pop(seg, offs)
    raise ArgumentError, "#{seg} is unwriteable" unless writeable? (seg)
    instr = []
    instr << comment_("pop #{seg} #{offs}")
    tempvar = "R13"
    instr << calculate_seg_addr_and_store_in_temp_var(seg, offs, tempvar)
    instr << pop_stack_top_to_D_register
    instr << ["@#{tempvar}", "A=M", "M=D"] 

    format_(instr)
    
  end


  ##########################################################################
  # Add assembler commands for examining the value at the top of the stack
  # and then jumping to the given label, if greater than zero
  def self.if_goto(name)
    instr = []
    instr << comment_("if-goto")
    instr << [pop_stack_top_to_D_register,
              "@#{name}",
              "D; JNE"]
    format_(instr)
  end


  ##########################################################################
  def self.goto(name)
    instr = [comment_("goto"), jump_to_func_(name)]
    format_(instr)
  end
  

  ##########################################################################
  def self.function_code(functionname, numlocals) 
    instr = [comment_("function entry #{functionname}"),
             label_(functionname), 
             comment_("init locals"),
             "D=0", "@LCL", "A=M"]
    0.upto(numlocals.to_i-1) { 
      instr << push_D_register_to_stack
    }
    instr << comment_("finished init locals")
    format_(instr)
  end


  ##########################################################################
  def self.function_return
    instr = [comment_("save FRAME(LCL) to a temp"), 
     "@LCL", "D=M", "@R13", "M=D", 

     comment_("save return address [*(FRAME-5)]"), 
     "@R13", "D=M", "@5", "A=D-A", "D=M", "@RET", "M=D",   

     comment_("*(ARG) = pop() - return the return value to caller"), 
     pop_stack_top_to_D_register, "@ARG", "A=M", "M=D", 

     comment_("set SP to ARG+1"), 
     "@ARG", "D=M", "D=D+1", "@SP", "M=D",   

     comment_("THAT = *(FRAME-1)"), 
     "@R13", "D=M", "@1", "A=D-A", "D=M", "@THAT", "M=D",      

     comment_("THIS = *(FRAME-2)"), 
     "@R13", "D=M", "@2", "A=D-A", "D=M", "@THIS", "M=D",      

     comment_("ARG= *(FRAME-3)"), 
     "@R13", "D=M", "@3", "A=D-A", "D=M", "@ARG", "M=D",      

     comment_("LCL = *(FRAME-4)"), 
     "@R13", "D=M", "@4", "A=D-A", "D=M", "@LCL", "M=D",      

     comment_("resume execution at return address of caller's code"), 
     "@RET", "A=M", "0; JMP"]   
    
    format_(instr)
  end 


  ##########################################################################
  def self.function_call(funcname, nArgs)
    instr = []

    # save the stack frame, for restoring state later 
    return_addr = "RETURNADDRESS#{next_return_label}"
    instr << save_stack_frame_(return_addr)

    # adjust the ARG and LCL base addresses
    # to prepare a new context for the about-to-be-invoked function 
    instr << adjust_ARG_(nArgs)
    instr << adjust_LCL_
  
    # jump to the function
    instr << jump_to_func_(funcname)
    
    # we are handling the "call f" vm command,
    # so the instr command after this sequence is where we 
    # want to return. 
    # So label it, in the instr.
    instr << label_(return_addr)

    format_(instr)
  end


  ##########################################################################
  def self.bootstrap
    instr = [comment_("START!!! SP=256"),
     "@256", "D=A", "@0", "M=D",
     comment_("Call Sys.init"),
	 function_call("Sys.init", 0)]
    format_(instr)
  end

  def self.label(name)
    instr = [label_(name)]
    format_(instr)
  end

  def self.set_scope(name)
    @@scope = name
  end


  private

  
    def self.get_new_label
    @@label = @@label.next
  end


  def self.next_return_label
    @@returns = @@returns.next
  end

 
  def self.comment_(arg)
    "// #{arg}"
  end
 

  def self.format_(instructions)
    instructions.flatten.map { |i|
      if ((i.start_with?('/') == false) && (i.start_with?('(') == false))
        "#{i.prepend("\t")}"
      else
        i
      end
    }
  end

  def self.label_(code)
    "(#{code})"
  end

  # write FALSE to the top of the stack
  def self.push_FALSE_to_stack
    ["@SP", "A=M", "M=0"]
  end
  

  # write TRUE to the top of the stack
  def self.push_TRUE_to_stack
    ["@SP", "A=M", "M=-1"]
  end


  def self.copy_stack_top_to_D_register
    ["@SP", "A=M", "D=M"]
  end
 
  def self.instr_for_push_argument_(n)
    [read_from_segment_and_store_in_D_register("argument", n),
     push_D_register_to_stack]
  end

   def self.adjust_ARG_(nArgs)
    [comment_("reposition ARG"), 
     "@5", "D=A", "@#{nArgs}", "D=D+A", 
     "@SP", "D=M-D", "@ARG", "M=D"]
  end

  def self.adjust_LCL_
    [comment_("reposition LCL"), 
     "@SP", "D=M", "@LCL", "M=D"]   
  end

  def self.jump_to_func_(funcname)
    [comment_("jump to #{funcname}"), 
     "@#{funcname}", "0; JEQ"]
  end

  def self.save_return_ROM_addr_(addr)
    ["@#{addr}",
     "D=A",
     push_D_register_to_stack]
  end

  def self.deref_ptr_and_save_(addr)
     ["@#{addr}",
     "D=M",
     push_D_register_to_stack]
  end

  def self.save_stack_frame_(returnaddr)
    [comment_("save stack frame"), 
     comment_("save return address"), 
     save_return_ROM_addr_(returnaddr),
     comment_("save LCL"), 
     deref_ptr_and_save_("LCL"),
     comment_("save ARG"), 
     deref_ptr_and_save_("ARG"),
     comment_("save THIS"), 
     deref_ptr_and_save_("THIS"),
     comment_("save THAT"), 
     deref_ptr_and_save_("THAT")]
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
    ["@SP", "A=M", "M=D", incrementSP]
  end


  # Assembler instructions to pop stack top to 
  # D register. NB - will always decrement the SP
  def self.pop_stack_top_to_D_register
    [decrementSP, copy_stack_top_to_D_register]
  end


  def self.store_constant_in_D_register(val)
    ["@#{val}", "D=A"] 
  end


  def self.calculate_seg_addr_and_store_in_A_register(seg, offs)
    case seg
    when "static" 
      ["@#{@@scope}.#{offs}"]
    when "pointer"
      if offs == "0" then ["@THIS"] end 
      if offs == "1" then ["@THAT"] end 
    else
      [store_constant_in_D_register(offs),
       "@#{@@segment2mnemonic[seg]}",
       "A=M+D"]
    end
  end


  def self.read_from_segment_and_store_in_D_register(seg, offs)
    if seg == "constant"
      return ["@#{offs}", "D=A"]
    else
      return [calculate_seg_addr_and_store_in_A_register(seg, offs),
              "D=M"]
    end
  end


  def self.calculate_seg_addr_and_store_in_temp_var(seg, offs, varname)
    return [calculate_seg_addr_and_store_in_A_register(seg, offs),
            "D=A", "@#{varname}", "M=D"]
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

  
  def self.writeable?(segment)
    writeable_segments = ["argument", "local",   "this", "pointer", 
                          "that",     "static",  "temp"] 

    return true if writeable_segments.include? segment 
    false
  end


 

  def self.comparison(truepathname, op, index)
    ["D=M-D",                        # D = *A-D 
     "@#{truepathname}#{index}", 
     "D; #{op}",                     # if comparison==true then jump 
     push_FALSE_to_stack,           # otherwise, push false to stack
     "@EXIT#{index}",      
     "0; JMP",                       # jump over the "true" branch 
     "(#{truepathname}#{index})",    # label for the "true" branch
     push_TRUE_to_stack,            # set to true
     "(EXIT#{index})"                # all branches lead here
    ]
  end


  def self.op_and_push(cmd)
    case cmd
    when :add 
      ["M=M+D"]
    when :sub 
      ["M=M-D"]
    when :and 
      ["M=M&D"]
    when :or 
      ["M=M|D"]
    when :neg 
      ["M=-M"]
    when :not 
      ["M=!M"]
    when :eq 
      comparison("EQUAL", "JEQ", get_new_label) 
    when :gt 
      comparison("GREATERTHAN", "JGT", get_new_label)
    when :lt 
      comparison("LESSTHAN", "JLT", get_new_label)
    end
  end 


end
