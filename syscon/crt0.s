
	.module crt0
	.globl    s__DATA
	.globl    l__DATA
	.globl    l__INITIALIZER
    .globl    s__INITIALIZER
    .globl    s__INITIALIZED
	.globl    _user_init
	.globl    _user_isr

	.area	_HEADER (ABS)
	;; Entry Point
	.org 	0x8000
	jp		user_init_stub
	jp		_user_isr

user_init_stub:
	call	gsinit
	call	_user_init
	ret

	;; Ordering of segments for the linker.
	.area	_HOME
	.area	_CODE
	.area	_INITIALIZER
	.area   _GSINIT
	.area   _GSFINAL

	.area	_DATA
	.area	_INITIALIZED
	.area	_BSEG
	.area   _BSS
	.area   _HEAP

	.area   _CODE

	.area   _GSINIT
gsinit::
	ld  hl, #s__DATA
	xor a
	ld  (hl),a
	ld  bc, #(l__DATA - 1)
	ld  a,b
	or  a,c
	jr  z, gsinit_1
	ld  de, #(s__DATA + 1)
	ldir

gsinit_1::
	ld	bc, #l__INITIALIZER
	ld  a,b
	or  a,c
	jr  z, gsinit_next
	ld	de, #s__INITIALIZED
	ld	hl, #s__INITIALIZER
	ldir


gsinit_next:

	.area   _GSFINAL
	ret

