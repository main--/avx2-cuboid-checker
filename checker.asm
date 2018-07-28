default rel
section .data
	align 32
shufl:
	%if 0
	;; shuffle mask to sort the shorts
	db 0, 1, 6, 7, 12, 13, 2, 3, 8, 9, 14, 15, 4, 5, 10, 11, 0, 1, 6, 7, 12, 13, 2, 3, 8, 9, 14, 15, 4, 5, 10, 11
	db 2, 3, 8, 9, 14, 15, 4, 5, 10, 11, 0, 1, 6, 7, 12, 13, 2, 3, 8, 9, 14, 15, 4, 5, 10, 11, 0, 1, 6, 7, 12, 13
	db 4, 5, 10, 11, 0, 1, 6, 7, 12, 13, 2, 3, 8, 9, 14, 15, 4, 5, 10, 11, 0, 1, 6, 7, 12, 13, 2, 3, 8, 9, 14, 15
	%else
	;; shuffle mask to sort byte-wise (more efficient)
	times 4 db 0, 6, 12, 2, 8, 14, 4, 10
	times 4 db 2, 8, 14, 4, 10, 0, 6, 12
	times 4 db 4, 10, 0, 6, 12, 2, 8, 14
	%endif

bounds:				; example: [16, 32[
	;; bounds are encoded as (((upper * -1) & 0x7fff), ((lower * -1) & 0x7fff))
	;; lower bound is inclusive, upper bound is exclusive
	times 16 dw 0x7fe0	; x upper bound: 32
	times 16 dw 0x7ff0	; x lower bound: 16
	times 16 dw 0x7fe0	; y upper bound
	times 16 dw 0x7ff0	; y lower bound
	times 16 dw 0x7fe0	; z upper bound
	times 16 dw 0x7ff0	; z lower bound
	
section .text
global test	
test:
	xor rcx, rcx

	;; load all our constants
	;; don't just call this, embed it into your function to avoid loading 288 bytes from memory every time
	vmovdqa ymm3, [shufl]
	vmovdqa ymm4, [shufl+0x20]
	vmovdqa ymm5, [shufl+0x40]
	vmovdqa ymm6, [bounds]
	vmovdqa ymm7, [bounds+0x20]
	vmovdqa ymm8, [bounds+0x40]
	vmovdqa ymm9, [bounds+0x60]
	vmovdqa ymm10, [bounds+0x80]
	vmovdqa ymm11, [bounds+0xa0]

%define iaca 0
.loop:
	%if iaca
	mov ebx, 111
	db 0x64, 0x67, 0x90
	%endif

	;; align your fucking inputs
	vmovdqa ymm0, [rdi + rcx]
	vmovdqa ymm1, [rdi + rcx + 0x20]
	vmovdqa ymm2, [rdi + rcx + 0x40]
	
	;; input in ymm0, ymm1, ymm2
	;; reassemble into pretty inputs [ymm0l, ymm1h], [ymm0h, ymm2l], [ymm1l, ymm2h]
	vpblendd ymm13, ymm2, ymm0, 0xf0 ; [ymm2l, ymm0h] (temporary)		p0125
	vpblendd ymm12, ymm0, ymm1, 0xf0 ; [ymm0l, ymm1h]			p0125
	vperm2i128 ymm13, ymm13, ymm13, 0b00000001 ; [ymm0h, yhh2l]		p5
	vpblendd ymm14, ymm1, ymm2, 0xf0 ; [ymm1l, ymm2h]			p0125

	;; input is nice, now get to work
	;; 1. allblend
	%if 1
	;; 16-bit blends: p5 each
	vpblendw ymm0, ymm12, ymm13, 0x92 ; almost all xs
	vpblendw ymm0, ymm0, ymm14, 0x24 ; xs complete
	vpblendw ymm1, ymm14, ymm12, 0x92 ; almost all ys
	vpblendw ymm1, ymm1, ymm13, 0x24 ; ys complete
	vpblendw ymm2, ymm13, ymm14, 0x92 ; almost all zs
	vpblendw ymm2, ymm2, ymm12, 0x24 ; zs complete
	%else
	;; 8-bit blends: 2p015
	;; This pipelines better in theory (reduces port 5 pressure) but turns out
	;; to be significantly slower as ports 0 and 1 are in use by the previous
	;; iteration's arithmetic ops.
	;; Plus the pipeline doesn't like dispatching 6 extra µops for no reason.
	vpblendvb ymm0, ymm12, ymm13, ymm9 ; almost all xs
	vpblendvb ymm0, ymm0, ymm14, ymm8 ; xs complete
	vpblendvb ymm1, ymm14, ymm12, ymm9 ; almost all ys
	vpblendvb ymm1, ymm1, ymm13, ymm8 ; ys complete
	vpblendvb ymm2, ymm13, ymm14, ymm9 ; almost all zs
	vpblendvb ymm2, ymm2, ymm12, ymm8 ; zs complete
	%endif

	;; could shuffle to fix the order here (useful for debugging)

	;; start operating
	;; let ymm6,7 ymm8,9 ymm10,11 be the lower,length bounds of x,y,z
	vpaddw ymm0, ymm0, ymm6	  ; subtract lower bound -> invalids underflow
	vpcmpgtw ymm0, ymm0, ymm7 ; if length > value: success
	vpaddw ymm1, ymm1, ymm8
	vpcmpgtw ymm1, ymm1, ymm9
	vpaddw ymm2, ymm2, ymm10
	vpcmpgtw ymm2, ymm2, ymm11

	;; shuffling before pipelines marginally better (next iteration's blends can already run in port5)
	;; but we use this shuffle to both fix the order AND pack the shorts into bytes so we don't have duplicate bits
	vpshufb ymm0, ymm0, ymm3
	vpshufb ymm1, ymm1, ymm4
	vpshufb ymm2, ymm2, ymm5

	;; combine results (need to shuffle at ANY point before this (items are not uniformly shuffled!)
	vpand ymm0, ymm0, ymm1
	vpand ymm0, ymm0, ymm2

	;; extract result
	vpmovmskb eax, ymm0	; 1 bit = 1 value (thanks to the shuffle)
	shr eax, 8		; [lane1 . lane1 . lane0 . lane0] -> [lane1 . lane1 . lane0]
	mov [rsi], ax		; write [lane1 . lane0]
	;; output is a bitfield (in case you haven't understood by now)

	;; port7 AGU is incapable of doing register additions, so we do it on port6
	add rsi, 2
	add rcx, 0x60
	cmp rcx, 256 * 3 * 2	; TODO: variable loop counter
	jnz .loop
	
	%if iaca
	mov ebx, 222
	db 0x64, 0x67, 0x90
	%endif
	
	ret
