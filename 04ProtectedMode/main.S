.code16
   cli #Clear interrupt flag

   xor %ax, %ax #Clear ax
   mov %ax, %ds #Clear ds

   #Clear text
   mov $0x0600, %ax
   mov $0x7, %bh
   mov $0x0, %cx
   mov $0x184f, %dx
   int $0x10

   #Reset Cursor
   mov $0x02, %ah
   mov $0x00, %bh
   mov $0, %dh
   mov $0, %dl
   int $0x10

   .equ CODE_SEG, 0x8
   .equ DATA_SEG, gdt_data - gdt_start

   lgdt gdt_descriptor #Tell the processor where our Global Descriptor Table is in memory

   mov %cr0, %eax 
   orl $0x1, %eax #Set cr0 bit 0 to enable (Protected Mode)
   mov %eax, %cr0

   #Code segment 0x8
   ljmp $CODE_SEG,$protected_mode #Need to clear instruction pipeline by doing a far jump to protected_mode label

gdt_start:
gdt_null:
   .long 0x0 #1[0-31]
   .long 0x0 #2[0-31]
gdt_code:
   .word 0xFFFF #Limit of 4GB 1[0-15]
   .word 0x0 #Base address at start of memory 1[16-31]
   .byte 0x0 #Base address at start of memory 2[0-7]
   .byte 0b10011010 #Type and privilge 2[8-15]
   .byte 0b11001111 #Limit 4GB 2[16-23]
   .byte 0x0 #Base address at start of memory 2[24-31]
gdt_data:
   .word 0xFFFF #Limit of 4GB 1[0-15]
   .word 0x0 #Base address at start of memory 1[16-31]
   .byte 0x0 #Base address at start of memory 2[0-7]
   .byte 0b10010010 #Type and privilge 2[8-15]
   .byte 0b11001111 #Limit 4GB 2[16-23]
   .byte 0x0 #Base address at start of memory 2[24-31]
gdt_end:
gdt_descriptor:
   .word gdt_end - gdt_start
   .long gdt_start

.code32

message:
   .asciz "Hello World Protegido"

protected_mode:
   #setup segments, code segments is updated by previous jump
   mov $DATA_SEG, %ax
   mov %ax, %ds
   mov %ax, %ss

   #Set stack
   mov $0x7000, %ebp
   mov %ebp, %esp

   .equ VGAWidth, 80

   #Local variable in stack index Y
   sub $2,%esp

   #Print message
   mov $message, %ecx
   mov $0, %eax #Clear eax for char 
   mov $0, %bx  #Clear bx for cursor X index
   movw $0, -2(%ebp) #Clear cursor Y index
   #0xB8000 video memory
   lea 0xB8000(%eax), %edx
   mov $0x1B, %ah # Character color
loop:
   mov (%ecx), %al #Load current char al
   cmp $0, %al #If end of string
   je end
   mov %ax, (%edx) #Print char
   add $1, %ecx #Increment string index
   add $2, %edx #Increment video index (each char 2 bytes)

   inc %bx; #Increment cursor x index
   cmp $VGAWidth,%bx
   jl  loop

   #If Index x is equal to with reset to 0 and increment Y index
   mov $0, %bx  #Clear bx for cursor X index
   addw $1,-2(%ebp) #Increment Y index

   jmp loop
end:
#Set cursor position
   #Get index Y from stack into ax
   mov -2(%ebp),%ax;
 
   #input bx = x, ax = y
	mov $VGAWidth, %dl
	mul %dl
	add %ax, %bx
 
   #input bx = cursor offset
	movw $0x03D4, %dx
	movb $0x0F, %al
	out %al, %dx
 
	inc %dl
	mov %bl, %al
	out %al, %dx
 
	dec %dl
	movb $0x0E,%al
	out %al, %dx
 
	inc %dl
	mov %bh,%al
	out %al, %dx

   hlt
