#---------------------------------------------------------------
# Assignment:           3
# Due Date:             March 10, 2017
# Name:                 Weihao Han
# Unix ID:              whan
# Lecture Section:      B1
# Instructor:           Karim Ali
# Lab Section:          H01 (Monday 14:00 - 16:50)
# Teaching Assistant:   
#---------------------------------------------------------------


	
#----------------------------------------------------------------------
# CubeStats compute  range and floor of elements in a cube specified by
# $a0 to $a3,and return results in $v0 & $v1
#
#
# Inputs:
#          a0:   the address of the top left corner of an n-dimensional cube
#          a1:   the edge size of the cube
#          a2:   the number of dimensions
#          a3:   the total edge size of the array
#
#                 
# Register Usage
#
#       t0: holds the element of PC 
#       t1: counter for determining whether change dimension
#       t2: store value of 1
#       t3: holds value of a3
#       t4: medium for calculation
#       t5: holds the original address
#	t6: counter of row in dimension 2
#	t7: counter of sub-cube in dimension 3
#
#----------------------------------------------------------------------

      .data
errorMes:
	.asciiz "Not albe to calculate result for dimension over 3 "

	
      .text


	
CubeStats:
	move $t1,$a1       #copy the edge as counter
	move $t5,$a0       #copy the original address
	addi $t2,$zero,1   #set for comparison as 1
	addi $t6,$zero,1   #set row counter
	move $t7,$t6       #counter for sub-cube
	addi $t4,$zero,3
	bgt $a2,$t4,directExit
	
calculation:
	lw $t0,0($t5)            #load the integer from PC
	lw $t4,total             #load the total num from RAM
	add $t4,$t4,$t0          #compute the new total
	sw $t4,total             #store the new total into RAM
	lw $t4,max               #load the max value from RAM  
	bgt $t0,$t4,changemax    #compare the current value with the max
	lw $t4,min               #load the min value from RAM
	blt $t0,$t4,changemin    #compare the current value with the min

caledge:
	addi $t1,$t1,-1               #decrease the counter by 1
	beq $t1,$zero,changeDimTwo    #change to next row if this row is done
	addi $t5,$t5,4                #change the address to the next element
	j calculation                 #do comparison for the next element

changeDimTwo:
	beq $t2,$a2,Exit             #If the array is of dimension 1,exit
	beq $t2,$a1,Exit             #If the the edge of cube is 1,exit
	beq $t6,$a1,changeDimThree   #Given that array dimension is more than 1
                                     #check whether the edge in dimension 2
	                             #is fille.If so,change next dimension
	move $t3,$a3                 #move the total edge size into t3
	sll $t3,$t3,2                #multiple number in t3 by 4
	add $t5,$t5,$t3              #change the PC to next row
	addi $t6,$t6,1               #add row counter by 1
	move $t1,$a1
	j calculation

changeDimThree:
	slti $t6,$a2,3            #set t6 to be 1 if array is of dimension 2
	bne $t6,$0,Exit           #If t6 was 1,then just exit
	beq $t7,$a1,Exit          #If the count of sub-cube equals edge of the
	                          #whole cube,exit
	mult $a3,$a3              #compute the distance to next top left corner
	sll $t3,$Lo,2             #multiple the result by 4
	add $a0,$a0,$t3           #change the new address to
	                          #nextthe top left corner
	move $t5,$a0              #move the new address to t5
        addi $t7,$t7,1            #increase the sub-cube counter by 1
	move $t6,$t2              #reset row counter to be 1
	j calculation
	
#change the maximum value to the current value
changemax:
	sw $t0,max
	j caledge

#change the minimum value to the current value	
changemin
	sw $t0,min
	j caledge

#compute the required result and return to main program
Exit:	
	subi $sp,$sp,4      #extend the stack
	sw $ra,0($sp)       #store the return address
	move $a0,$a1        #move the edge size to a0
	move $a1,$a2        #move the dimension to a1
	jal power           #call subroutine to calculate number of elements
	lw $ra,0($sp)       #load the return address
	addi $sp,$sp,4
	move $t4,$v0        #move the # of elements in t4
	lw $t6,total        #load the total amount into t6
	div $t6,$t4         #divide t6 by t4
	move $v1,$Lo        #put the integer quotient into v1
	lw $t4,min          #load the minimum value into t4
	lw $t6,max          #load the maximum value into t6
	sub $v0,$t6,$t4     #get the range
	jr $ra

directExit:
	li  $v0,4
	la  $a0,errorMes
	syscall
	jr $ra
