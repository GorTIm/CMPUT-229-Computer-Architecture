#---------------------------------------------------------------
# Assignment:           5
# Due Date:             April 12, 2017
# Name:                 Weihao Han
# Unix ID:              whan
# Lecture Section:      B1
# Instructor:           Karim Ali
# Lab Section:          H01 (Monday 14:00 - 16:50)
# Teaching Assistant:   
#---------------------------------------------------------------


#----------------------------------------------------------------------
# 
# 
#
#
#
# Inputs:
#
#          
#                 
# Register Usage
#
#       t0:register for storing address of current entry
#       t1:store the char to compute hash code/store the entry to be test
#	t2:store integer 128
#       t3:	
#	t4:unique identifier component(restrict use)
#       t5:counter of length of the string(restrict use)
#       t6:register for storing various values
#       t7:
#       t8:unique index for unbounded data structure	
#       t9:contain the address of interning string
#	   and never change(restrict use)
#----------------------------------------------------------------------

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
	div $t1,$t2                 #divide t1 by t2
	mfhi $t1                    #move the remainder of previous division
	                            #to t1
	
	add $t3,$t3,$t1             #add the remainder into sum counter
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
	lw $a0,$t5     #for the interning string,the amount of bytes needed is
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
	lw $a0,$t5     #for the string,the amount of bytes needed is
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
	lw $a0,$t5     #for the interning string,the amount of bytes needed is
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
