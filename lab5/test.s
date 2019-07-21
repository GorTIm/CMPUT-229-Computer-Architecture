#---------------------------------------------------------------
# Student Test File for Interning Lab
# Author: Taylor Lloyd
# Date: July 12, 2012
#---------------------------------------------------------------


#-------------------------------------------
# Bug fixing - Nov 23, 2014
# 
# Author: Alejandro Ramirez
# 
# Added a check to avoid problems
# with strings that have not been
# interned. 
#
#-------------------------------------------

.data

instructions:
	.asciiz	"Enter 'i' to intern, 'g' to retrieve, 'f' to intern a file, 'q' to quit:"
internText:
	.asciiz	"String to intern:"
internReturn:
	.asciiz "Identifier:"
fInternText:
	.asciiz	"File to intern:"
sErr:
	.asciiz "String has not been interned.\n"
fErr:
	.asciiz "Error opening file.\n"
fInternReturn:
	.asciiz "Identifiers:\n"
getText:
	.asciiz	"Identifier to retrieve:"
getReturn:
	.asciiz "String:"
err:	.asciiz "Unrecognized command.\n"
nlStr:	.asciiz "\n"
cmd:	.space 256
	.align 2
fileMem:.space 2048

.text
main:
	mainLoop:
		#instructions message
		la	$a0 instructions
		li	$v0 4
		syscall

		#read input
		la	$a0 cmd
		li	$a1 16
		li	$v0 8
		syscall

		#intern?
		lb	$t0 cmd
		li	$t1 'i'
		beq	$t0 $t1 intern

		#file intern?
		lb	$t0 cmd
		li	$t1 'f'
		beq	$t0 $t1 file

		#retrieve?
		li	$t1 'g'
		beq	$t0 $t1 get

		#quit?
		li	$t1 'q'
		beq	$t0 $t1 die

		#error & loop back
		la	$a0 err
		li	$v0 4
		syscall
		j	mainLoop

	intern:
		#prompt
		la	$a0 internText
		li	$v0 4
		syscall
		
		#allocate space for string
		li	$a0 256
		li	$v0 9
		syscall

		#read string to newly allocated space
		move	$a0 $v0
		li	$a1 256
		li	$v0 8
		syscall
		move	$s0 $a0

		#drop newline from end
		li	$t0 0x0A
		move	$t1 $s0
		intern_drop_nl:
			lb	$t2 0($t1)
			beqz	$t2 intern_drop_done
			beq	$t0 $t2 intern_store
			addi	$t1 $t1 1
			j	intern_drop_nl
		intern_store:
			sb	$0 0($t1)
		intern_drop_done:

		#prettify
		la	$a0 internReturn
		li	$v0 4
		syscall

		#call internString
		move	$a0 $s0
		jal	internString

		#print identifier
		move	$a0 $v0
		li	$v0 1
		syscall

		#print newline
		la	$a0 nlStr
		li	$v0 4
		syscall

		j	mainLoop
	file:
		#prompt
		la	$a0 fInternText
		li	$v0 4
		syscall

		#read filename
		la	$a0 cmd
		li	$a1 256
		li	$v0 8
		syscall
		
		#drop newline from end
		li	$t0 0x0A
		la	$t1 cmd
		file_drop_nl:
			lb	$t2 0($t1)
			beqz	$t2 file_drop_done
			beq	$t0 $t2 file_store
			addi	$t1 $t1 1
			j	file_drop_nl
		file_store:
			sb	$0 0($t1)
		file_drop_done:
		

		li	$a1 0		#read
		li	$a2 0x0644
		li	$v0 13
		syscall
	
		li	$t0 -1
		beq	$v0 $t0 printFileErr

		move	$a0 $v0
		la	$a1 fileMem
		li	$a2 2048
		li	$v0 14
		syscall

		#Place EOT at end of file
		add	$t0 $a1 $v0
		li	$t1 4	#EOT
		sb	$t1 0($t0)

		#Close file
		li	$v0 16
		syscall

		#prettify
		la	$a0 fInternReturn
		li	$v0 4
		syscall

		#call internFile
		la	$a0 fileMem
		jal	internFile
		
		#print all identifiers
		move	$t0 $v0
		move	$t1 $v1
		fileIDPrint:
			lw	$a0 0($t0)
			li	$v0 1
			syscall

			#print newline
			la	$a0 nlStr
			li	$v0 4
			syscall
			
			addi	$t0 $t0 4
			addi	$t1 $t1 -1

			bgtz	$t1 fileIDPrint

		j	mainLoop

	get:
		#prompt
		la	$a0 getText
		li	$v0 4
		syscall

		#read number
		li	$v0 5
		syscall
		move	$s0 $v0

		#prettify
		la	$a0 getReturn
		li	$v0 4
		syscall

		#call getInternedString
		move	$a0 $s0
		jal	getInternedString

		#check if it is not zero
		beqz 	$v0 printStringErr 

		#print it
		move	$a0 $v0
		li	$v0 4
		syscall

		#print newline
		la	$a0 nlStr
		li	$v0 4
		syscall

		j	mainLoop

	printStringErr: 
		la	$a0 sErr
		li 	$v0 4
		syscall
		j 	mainLoop

	printFileErr:
		la	$a0 fErr
		li	$v0 4
		syscall
		j	mainLoop

	die:
		li	$v0 10
		syscall
		
######################## STUDENT CODE BEGINS HERE ##########################
	.data

hashtalbe:	.space 512  #an large space as hashtable containing at
	                    #most 128 different addresses of string
	.text



internString:
	move $t0,$a0        #copy the address of mutable string in a0 into t0
	lb $t1,0($t0)       #load the first character of the string into t1
	addi $t2,$zero,128  #set t2 to be 128 for further divsion operation
	move $t3,$zero      #set t3 to zero as sum of remainder
	move $t5,$zero      #set t5 as counter of length of the string
	move $t8,$zero
	move $t9,$a0
hashing:
	beq $t1,$zero,examineEntry  #test if t1 is a null.If yes,skip the loop
	                            #otherwise,go into the loop
	add $t3,$t3,$t1             #add the remainder into sum counter
	div $t3,$t2                 #divide t3 by t2
	mfhi $t3                    #move the remainder of previous division
	                            #to t1
	

	addi $t0,$t0,1              #move to address of next character
	addi $t5,$t5,1
	lb $t1,0($t0)               #load the next character into t1
	j hashing

#From previous operation,we have t3 as the entry index
examineEntry:
	move $t4,$t3             #store the index of the string
	
	la $t0,hashtalbe         #load the address of first element of hashtable
	sll $t3,$t3,2            #multiple t3 by 4
	add $t0,$t0,$t3          #find the address of entry to be examined
	lw  $t1,0($t0)           #load the entry into t1
	
	beq $t1,$zero,createNewEntry #If t1 equal zero,it means the entry
	                             #is empty and direct operation is ok
	
	srl $t3,$t1,31               #mask out the bit31 to t3
	beq $t3,$zero,entryExist     #If the bit31 is zero,which means entry
	                             #already exist and collision may occurs
	                             #So we need to check wheter the interning
	                             #string matches the entry
	                             #If not,we need to create a linked list
	                             #to contain multiple string address
	
	lui $t2,0x8000          #load the 32bit 0x80000000 into t2
	xor $t1,$t1,$t2         #reset the most-significant bit of address
	                        #of a linked list to be 0 for further use

stringComparing:	
	move $t3,$t9            #move the address of interning string into
	                        #t3
	
	lw $t2,0($t1)          #load the address of immutable string into t2
characterComparing:	
	lb $t6,0($t2)           #load the character of immutable string into t6
	lb $t7,0($t3)           #load the character of interning string into t7
	bne $t6,$t7,nextString  #If the current string in this node did not
	                        #match,try next node
	                      
	beq $t6,$zero,matchGet  #When two string matches,go to matchGet
	addi $t2,$t2,1
	addi $t3,$t3,1
	j characterComparing
	
nextString:	
	lw $t2,4($t1)               #load the address of the next node
	addi $t8,$t8,0x0100         #add  1 to bit8 for t8

	beq $t2,$zero,insertString  #If the pointer part is zero,it means
	                            #all nodes of the linked list has been
	                            #go through but no one matches,then
	                            #a new node has to be created
	
        lw $t1,0($t2)               #load the address of the string in
	                            #the next node
	j  stringComparing

matchGet:
	or $v0,$t8,$t4            #use or to combine the bit pattern of hashcode
	                          #in hashtable with unique index in
	                          #linked list
	jr $ra

insertString:
	li $v0,9       #use system call 9 to allocate immutable memory
	li $a0,8       #for a new node in the linked list
	               #the amount of bytes needed is 8
	syscall
	sw $v0,4($t1)  #store the address of new node in pointer part
	               #of the last node
	
	move $t1,$v0   #move the address of new node to t1
	
	li $v0,9       #use system call 9 to allocate immutable memory
	move $a0,$t5     #for the interning string,the amount of bytes needed is
	syscall        #identified by the the length of the string
	               #which was stored in t5
 	sw $v0,0($t1)  #store the address of immutable memory into data part
	               #of new node
	move $t1,$v0   #move the address of immutable memory to t1
	move $t2,$t9   #move the address of interning string to t2
copyloop:
	lb $t6,0($t2)  #load the character of interning string to t7
	beq $t6,$zero,exit

	sb $t6,0($t1)  #store the character of interning string
	               #into immutable memory
	addi $t2,$t2,1 #move to next character of interning string 
	addi $t1,$t1,1 #move to next byte of immutable memory
	j copyloop
	
exit:
	or $v0,$t8,$t4            #use or to combine the bit pattern of hashcode
	                          #in hashtable with unique index in
	                          #linked list
	jr $ra
	
	


createNewEntry:
	li $v0,9       #use system call 9 to allocate immutable memory
	move $a0,$t5     #for the string,the amount of bytes needed is
	syscall        #identified by the the length of the string
	               #which was stored in t5

	sw $v0,0($t0)  #store the starting address of the immutable string
	               #into entry whose address was in t0
	
	move $t0,$t9   #move the address of the mutable string into t0

copyString:
	lb $t1,0($t0)               #load a character into t1
	beq $t1,$zero,quit1          #If encounter the null char,
	                            #quit the loop
	
	sb $t1,0($v0)               #store the character into the address
	                            #in v0
	
	addi $t0,$t0,1              #move to address of next character of
	                            #mutable string
	
	addi $v0,$v0,1              #move to next address of allocated memory
	j copyString

quit1:
	move $v0,$t4  #move the index in the hashtable
	              #as unique identifier directly
	jr $ra


entryExist:
	move $t2,$t9   #move the address of interning string into t2

compareString:
	lb $t3,0($t1)              #load the character of string whose address
	                           #is in hashtable entry
	lb $t6,0($t2)              #load the character of mutable string
	bne $t3,$t6,createNewList  #If difference occurs,to handle overflows
	                           #a linked list need to be created
	
	beq $t6,$zero,quit1        #If both char equal zero,which means two
	                           #strings matches,then go to quit1
 	addi $t1,$t1,1
	addi $t2,$t2,1
	j compareString
	
createNewList:
	li $v0,9       #use system call 9 to allocate immutable memory
	li $a0,8       #for the string,the amount of bytes needed is
	syscall        #8 in order to store two address

	lw $t1,0($t0)  #load the address of string in hashtable into t1
        sw $t1,0($v0)  #store the entry into the value of first node
	               #of the linked list
	
	sw $v0,0($t0)  #replace content of the bucket with address of
	               #the newly created linked list

	li $v0,9       #use system call 9 to allocate immutable memory
	move $a0,$t5     #for the interning string,the amount of bytes needed is
	syscall        #identified by the the length of the string
	               #which was stored in t5
	move $t1,$v0
	move $t2,$t9   #move the address of interning string into t2

stringCopying:
	lb $t3,0($t2)         #load one character from the interning  string
	beq $t3,$zero,quit2   #When string copying end,go to quit2

	sb $t3,0($t1)
	addi $t1,$t1,1
	addi $t2,$t2,1
	j stringCopying
	
quit2:
	lw $t1,0($t0)  #load the address of linked list into t1
	
	move $t3,$v0   #store the address of the immutable copy into t3
	
	li $v0,9       #use system call 9 to allocate immutable memory
	li $a0,8       #for a new node in the linked list
	               #the amount of bytes needed is 8
	syscall

	sw $v0,4($t1)  #store the address of second node in the pointer
	               #part of first node
	sw $t3,0($v0)  #store the address of the immutable copy into
	               #the data part of second node
	
	

	
	lw $t1,0($t0)  #load the address of linked list
	lui $t2,0x8000 #load the 32bit 0x80000000 into t2
	or $t1,$t1,$t2 #set the most-significant bit of address of linked list 
                       #to be 1
	sw $t1,0($t0)

	ori $t4,$t4,0x0100 #set the bit8 of the index in hashtable  as 1

	move $v0,$t4     #move the value as unique identifier

	jr $ra

#----------------------------------------------------------------------
# The getInternedString subroutine take an value as unique identifier
# of a string and eventually return an address in immutable memory of a
# string corresponding to the unique identifier
#
#
#
# Inputs:
#       a0:interned string identifier	
#
#          
#                 
# Register Usage
#
#       t0:store the address 
#       t1:store the index in hashtable
#	t2:store the index in the linklist if it exist 
#       t3:hold the address of a string/linked list	
#
#----------------------------------------------------------------------
getInternedString:
	andi $t1,$a0,0x00FF     #mask out the index in hashtable
	andi $t2,$a0,0xFF00     #mask out the index in the linklist
	srl $t2,$t2,8           #shift right to get the exact index in the
	                        #linked list(if it really exist)

	la $t0,hashtalbe        #load the address of first element of hashtable
	sll $t1,$t1,2            #multiple t1,the index, by 4
	add $t0,$t0,$t1          #find the address of entry to be examined

	
	lw  $t3,0($t0)           #load the entry into t3
	beq $t3,$zero,quit3      #If the entry equal zero,its means the string
	                         #was not interned before
	srl $t1,$t3,31           #mask out bit31 of the entry
	
	beq $t1,$zero,quit4      #If bit31 equal zero,it means that the entry
	                         #contains an address of string
	                         #Otherwise,it implys that a link list
	                         #exist in this entry
	
	lui $t1,0x8000           #load the 32bit int 0x80000000 into t1
	xor $t3,$t1,$t3          #get the address of the linked list
	move $t1,$zero           #set t1 as the index counter of linked list

checkList:
	beq $t1,$t2,return
	lw $t4,4($t3)          #load the pointer part of the node in t4
	beq $t4,$zero,quit3    #If it points to null,it means no further nodes
	                       #nodes exist,but linked list index needs further
	                       #move,so the string was not interned
	addi $t1,$t1,1         #add 1 to the index counter
	move $t3,$t4
	j checkList
	
return:
	lw $v0,0($t3)          #load the address stored in data part of node
	                       #into v0 as return value
        jr $ra

quit3:
	move $v0,$zero
	jr $ra

quit4:
	bne $t2,$zero,quit3 #If t2 not equal zero,it means the unique
	                    #identifier was going to find a string in 
	                    #linked list however no linked list in this entry
	move $v0,$t3
	jr $ra
	

#----------------------------------------------------------------------
#The internFile takes a pointer to a file as input and collect the unique
#identifiers of  all strings inside the file.Finally it will return a
#pointer to a list containing all identifiers and an integer representing
#number of identifiers in the list. If a string appears multiple times
#in the file, its identifier should also appear multiple times
#in the identifier list# Strings should be split at each space or
#line feed character. 
#
# Inputs:
#       a0:interned string identifier	
#
#          
#                 
# Register Usage
#
#       t0:the address of a splited string
#       t1:
#	t2: 
#       t3:
#       t4:indicator for special case of fetching string
#       t5:
#----------------------------------------------------------------------
	.data
idList:		.space 512  #allocate 512 bytes for at most 128 different
	                    #integer identifiers
	.text

	
internFile:
	move $t0,$a0     #t0 store the start address of a file
	move $t4,$zero   #set t4 to zero indicate no special case occur
	move $t5,$zero   #t5 is the counter of identifiers in the list

checkSplit:	
	lb $t1,0($t0)
	move $t2,$zero
	addi $t2,$t2,0x20
	beq  $t1,$t2,moveForward  #If the current byte is a space,move to next
	                          #byte and start a new check on it 
	
	move $t2,$zero
	addi $t2,$t2,0x0A
	beq  $t1,$t2,moveForward  #If the current byte is a line feed,move to
	                          #next byte and start a new check
	move $t2,$zero
	addi $t2,$t2,0x04
	beq  $t1,$t2,endOfFile    #If the current byte is a EOT byte,stop and
	                          #return required values
	move $t3,$t0             #keep the address of current character in t3

fetchString:	
	lb $t1,1($t3)            #load the next byte into t1
	
	move $t2,$zero
	addi $t2,$t2,0x20
	beq $t1,$t2,getId         #If the next byte is a space,its point to
	                         #split the string

	move $t2,$zero
	addi $t2,$t2,0x0A
	beq  $t1,$t2,getId        #If the current byte is a line feed,move to
	                          #next byte and start a new check

	move $t2,$zero
	addi $t2,$t2,0x04
	
	beq  $t1,$t2,setIndicator  #If the end the the string is the EOT byte
	                           #set special indicator for it

	
	addi $t3,$t3,1            #move to next byte
	j fetchString

setIndicator:
	addi $t4,$zero,1
	j getId
	
	
getId:
	
	
	sb $zero,0($t3)          #set null character to indicate end of string
	
	addi $sp,$sp,-36
	sw $ra,0($sp)
	sw $t0,4($sp)
	sw $t1,8($sp)
	sw $t2,12($sp)
	sw $t3,16($sp)
	sw $t4,20($sp)
	sw $t5,24($sp)
	sw $a0,28($sp)
	sw $fp,32($sp)

	move $a0,$t0
	
	jal internString


	lw $ra,0($sp)   #restore all the values
	lw $t0,4($sp)
	lw $t1,8($sp)
	lw $t2,12($sp)
	lw $t3,16($sp)
	lw $t4,20($sp)
	lw $t5,24($sp)
	lw $a0,28($sp)
	lw $fp,32($sp)
	addi $sp,$sp,36

	la $t1,idList
	sll $t2,$t5,2       #multiple the index by 4 to get address
	                    #to store unique identifier
	add $t1,$t1,$t2

	sw $v0,0($t1)       #store the unique identifier in the list

	addi $t5,$t5,1       #once a string fetched,add 1 to the counter

	bne $t4,$zero,endOfFile

	addi $t0,$t3,1       #go to  the next byte after the end of
	                     #string and start find another string
	
	

	j checkSplit


	

moveForward:
	addi $t0,$t0,1
	j checkSplit


endOfFile:
	la $v0,idList
	move $v1,$t5

	jr $ra
