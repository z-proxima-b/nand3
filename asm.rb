module Asm

  @@segment2mnemonic = { "argument" => "ARG",
                         "local" => "LCL",
                         "this" => "THIS",
                         "that" => "THAT"}
                          

  @@label = 0
  @@fname = ""

  def self.set_file_name(name)
    @@fname = name
  end

  def self.get_new_label
    @@label = @@label.next
  end

  def self.write_comment(type, *args)
    case type
    when :arithmetic
      ["//#{args[0]}"]
    when :push
      ["// push #{args}"]
    when :pop
      ["// pop #{args}"]
    end
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

  # Assembler instructions to pop stack top to 
  # D register. NB - will always decrement the SP
  def self.pop_stack_top_to_D_register
    [decrementSP, "@SP", "A=M", "D=M"].flatten
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
  def self.stack_push(seg, offs)
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
  def self.stack_pop(seg, offs)
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

end
