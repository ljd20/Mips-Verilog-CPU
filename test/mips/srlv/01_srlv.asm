# Expect: 0x333566E0

.text
.globl main
main:
    la		$v0,  0x666ACDC1
    la		$t0,  0x00000101
    srlv    $v0, $v0, $t0
    jr      $zero	
