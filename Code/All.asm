.globl _start
_start:

li x4, 100
add x1, x2, x3

lui x0, 111
auipc x1, 222
jal x2, label
jalr x3, x4, 888

label: 

addi x0, x1, 111
slti x1, x2, 222
sltiu x2, x3, 333
xori x3, x4, 444
ori x4, x5, 555
andi x5, x6, 666
slli x6, x7, 7
srli x7, x8, 8
srai x8, x9, 9

add x0, x1, x2
sub x1, x2, x3
sll x2, x3, x4
slt x3, x4, x5
sltu x4, x5, x6
xor x5, x6, x7
srl x6, x7, x8
sra x7, x8, x9
or x8, x9, x10
and x9, x10, x11

beq x0, x1,  branch_here
bne x1, x2,  branch_here
blt x2, x3,  branch_here
bge x3, x4,  branch_here
bltu x4, x5, branch_here
bgeu x5, x6, branch_here

branch_here:

lb x0, 111(x1)
lh x1, 222(x2)
lw x2, 333(x3)
lbu x3, 444(x4)
lhu x4, 555(x5)

sb x0, 111(x1)
sh x1, 242(x2)
sw x2, 333(x3)

