; Boot Signature
.byt $55
.byt $AA

; Boot Block Size (in 16-byte blocks)
.byt $3F
.byt $00

; Boot Block Offset (in bytes)
.byt $10
.byt $00

; Padding
.dsb $A

; Boot Code
ldy #1 : lda #$55 : sta ($04),Y
ldy #0 : lda #$10 : sta ($04),Y
ldy #1 : lda #$50 : sta ($04),Y
ldy #0 : lda #$10 : sta ($04),Y
ldy #1 : lda #$21 : sta ($04),Y
ldy #0 : lda #$10 : sta ($04),Y
ldy #1 : lda #$0A : sta ($04),Y
ldy #0 : lda #$10 : sta ($04),Y

; Padding
.dsb 960
