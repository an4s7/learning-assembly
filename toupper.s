#
# Purpose: Converts input file leters to uppercase in the output file.
# Usage: ./toupper input_file.txt output_file.txt

#Code related to Programming from the Ground Up, in x86 AT&T assembly.

#Assemble using **as**:
#`as -32 foo.s -o foo.o`

#Link using **ld**:
#`ld -m elf_i386 foo.o -o foo`
#-----------------------------------------------------------------------#
.section  .data

# system call nums
.equ SYS_OPEN, 5
.equ SYS_WRITE, 4
.equ SYS_READ, 3
.equ SYS_CLOSE, 6
.equ SYS_EXIT, 1

#options for open
.equ O_RDONLY, 0
.equ O_CREAT_WRONLY_TRUNC, 03101

#std file descriptors
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

# syscal int
.equ LINUX_SYSCALL, 0x80
.equ EOF, 0
.equ NUM_ARGS, 2

.section .bss
#BUFFER
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE

.section .text

#STACK POSITIONS
.equ ST_SIZE_RESERVE, 8
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8
.equ ST_ARGC, 0      #NUMBER OF ARGS 
.equ ST_ARGV_0, 4    #NAME OF PROG
.equ ST_ARGV_1, 8    #INPUT FILE NAME
.equ ST_ARGV_2, 12   #OUTPUT FILE NAME

.global _start
_start:

movl %esp,%ebp
subl $ST_SIZE_RESERVE,%esp

open_files:
open_fd_in:
 movl $SYS_OPEN, %eax
 movl ST_ARGV_1(%ebp), %ebx
 movl $O_RDONLY, %ecx
 movl $0666,%edx
 int  $LINUX_SYSCALL

store_fd_in:
 movl %eax,ST_FD_IN(%ebp)

open_fd_out:
  
 movl $SYS_OPEN, %eax
 movl ST_ARGV_2(%ebp), %ebx
 movl $O_CREAT_WRONLY_TRUNC, %ecx
 movl $0666, %edx
 int $LINUX_SYSCALL

store_fd_out:
 movl %eax,ST_FD_OUT(%ebp)

read_loop_begin:

 movl $SYS_READ, %eax
 movl ST_FD_IN(%ebp),%ebx
 movl $BUFFER_DATA,%ecx
 movl $BUFFER_SIZE,%edx
 int $LINUX_SYSCALL

 cmpl $EOF,%eax
 jle end_loop

continue_read_loop:
 pushl $BUFFER_DATA
 pushl %eax
 call convert_to_upper
 popl %eax
 addl $4,%esp

 movl %eax,%edx
 movl $SYS_WRITE,%eax
 movl ST_FD_OUT(%ebp),%ebx
 movl $BUFFER_DATA, %ecx
 int  $LINUX_SYSCALL

 jmp read_loop_begin

end_loop:

 movl $SYS_CLOSE,%eax
 movl ST_FD_OUT(%ebp),%ebx
 int  $LINUX_SYSCALL

 movl $SYS_CLOSE,%eax
 movl ST_FD_IN(%ebp),%ebx
 int  $LINUX_SYSCALL

 movl $SYS_EXIT,%eax
 movl $0,%ebx
 int  $LINUX_SYSCALL

# upper case coversion for a block:
#	
# vars: eax - beggining of buffer
#       ebx - length of bffer
#       edi - current buffer offset
#       cl - lower byte
#
# Instead of calculating the value 'A' - 'a',and add this to the L.O 
# byte in %cl i used the fact that the ASCII codes for letters only 
# differs in bit 5 from upper case to lower. So with a AND with 0xDF
# on %cl flips the 5 bit and does the conversion.
#
# ascii:
#  (e = 01100101) and (0xDF = 11011111) = 
#  (E = 01000101)

.equ LOWERCASE_A, 'a'
.equ LOWERCASE_Z, 'z'
.equ ST_BUFFER_LEN, 8
.equ ST_BUFFER, 12

.type convert_to_upper,@function
convert_to_upper:
 pushl %ebp
 movl %esp,%ebp
 
 movl ST_BUFFER(%ebp),%eax     #loads the buffer and buffer size
 movl ST_BUFFER_LEN(%ebp),%ebx
 movl $0,%edi

 cmpl $0,%ebx                  #if buffer size = 0 
 je end_convert_loop           #end loop 

convert_loop:
 movb (%eax,%edi,1),%cl

 cmpb $LOWERCASE_A, %cl     #checks to se if its the 'a'-'z' range
 jl next_byte               
 cmpb $LOWERCASE_Z, %cl
 jg next_byte

 andb $0xDF,%cl             #mask!
 movb %cl,(%eax,%edi,1)

next_byte:
 incl %edi
 cmpl %edi,%ebx
 jne convert_loop

end_convert_loop:
 movl %ebp,%esp
 popl %ebp
 ret













