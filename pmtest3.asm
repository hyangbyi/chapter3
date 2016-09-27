%include	"pm.inc"
	org 0x100
	core_length	dd	core_end - 0x100
	core_entry	dw	LABEL_BEGIN
			dw	0x0000

	[SECTION .gdt]
LABEL_GDT:		Descriptor	0,	0,		0
LABEL_DESC_NORMAL:	Descriptor	0,	0xffff,		DA_DRW
LABEL_DESC_CODE32:	Descriptor	0,	SegCode32Len-1,	DA_C + DA_32
LABEL_DESC_CODE16:	Descriptor	0,	0xffff,		DA_C
LABEL_DESC_DATA:	Descriptor	0,	DataLen-1,	DA_DRW+DA_DPL1
LABEL_DESC_STACK:	Descriptor	0,	TopOfStack,	DA_DRWA+DA_32
LABEL_DESC_LDT:		Descriptor	0,	LDTLen-1,	DA_LDT
LABEL_DESC_VIDEO:	Descriptor	0xb8000,	0xffff,		DA_DRW

	GdtLen	equ	$-LABEL_GDT
	GdtPtr	dw	GdtLen-1
		dd	0

SelectorNormal		equ	LABEL_DESC_NORMAL	-LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32	-LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16	-LABEL_GDT
SelectorData		equ	LABEL_DESC_DATA		-LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK	-LABEL_GDT
SelectorLDT		equ	LABEL_DESC_LDT		-LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	-LABEL_GDT

	[SECTION .data1]
	ALIGN	32
	[BITS	32]
LABEL_DATA:
SPValueInRealMode		dw	0
PMMessage:			db	"In Protect Mode now.^-^", 0
OffsetPMMessage			equ	PMMessage - $$
StrTest:			db 	"ABKLDFJDFKADKDF", 0
OffsetStrTest			equ	StrTest - $$
DataLen				equ	$ - LABEL_DATA

	[SECTION .gs]
	ALIGN	32
	[BITS	32]
LABEL_STACK:
	times	512	db	0
	TopOfStack	equ	$ - LABEL_STACK - 1

	[SECTION .s16]
	[BITS	16]
LABEL_BEGIN:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x100

	mov [LABEL_GO_BACK_TO_REAL + 3], ax
	mov [SPValueInRealMode], sp

	mov ax, cs
	movzx eax, ax
	shl eax, 4
	add eax, LABEL_SEG_CODE16
	mov word [LABEL_DESC_CODE16 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE16 + 4], al
	mov byte [LABEL_DESC_CODE16 + 7], ah

	xor eax, eax
	mov ax, cs
	shl eax, 4
	add eax, LABEL_SEG_CODE32
	mov word [LABEL_DESC_CODE32 + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_CODE32 + 4], al
	mov byte [LABEL_DESC_CODE32 + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_DATA
	mov word [LABEL_DESC_DATA + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_DATA + 4], al
	mov byte [LABEL_DESC_DATA + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_STACK
	mov word [LABEL_DESC_STACK + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_STACK + 4], al
	mov byte [LABEL_DESC_STACK + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_LDT
	mov word [LABEL_DESC_LDT + 2], ax
	shr eax, 16
	mov byte [LABEL_DESC_LDT + 4], al
	mov byte [LABEL_DESC_LDT + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_CODE_A
	mov word [LABEL_LDT_DESC_CODEA + 2], ax
	shr eax, 16
	mov byte [LABEL_LDT_DESC_CODEA + 4], al
	mov byte [LABEL_LDT_DESC_CODEA + 7], ah

	xor eax, eax
	mov ax, ds
	shl eax, 4
	add eax, LABEL_GDT
	mov dword [GdtPtr + 2], eax
	lgdt [GdtPtr]
	cli
	in al, 0x92
	or al, 0000_0010b
	out 0x92, al
	mov eax, cr0
	or eax, 1
	mov cr0, eax

	jmp dword SelectorCode32:0 ;b 0x46d

LABEL_REAL_ENTRY:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, [SPValueInRealMode]
	in al, 0x92
	and al, 1111_1101b
	out 0x92, al
	sti
	jmp $

	[SECTION .s32]
	[BITS 32]
LABEL_SEG_CODE32:
	mov ax, SelectorData
	mov ds, ax
	mov ax, SelectorVideo
	mov gs, ax
	mov ax, SelectorStack
	mov ss, ax
	mov esp, TopOfStack

	mov ah, 0x0c
	xor esi, esi
	xor edi, edi
	mov esi, OffsetPMMessage
	mov edi, (80 * 10 + 0) * 2
	cld
.1:
	lodsb
	test al, al
	jz .2
	mov [gs:edi], ax
	add edi, 2
	jmp .1
.2:
	call DispReturn
	mov ax, SelectorLDT
	lldt ax			;b 0x4cb
	jmp SelectorLDTCodeA:0

DispReturn:
	push eax
	push ebx
	mov eax, edi
	mov bl, 160
	div bl
	and eax, 0xff
	inc eax
	mov bl, 160
	mul bl
	mov edi, eax
	pop ebx
	pop eax
	ret

SegCode32Len	equ	$ - LABEL_SEG_CODE32

	[SECTION .s16code]
	ALIGN 32
	[BITS 16]
LABEL_SEG_CODE16:
	mov ax, SelectorNormal
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov eax, cr0
	and al, 1111_1110b
	mov cr0, eax
LABEL_GO_BACK_TO_REAL:
	jmp 0:LABEL_REAL_ENTRY

	Code16Len	equ	$ -LABEL_SEG_CODE16



	[SECTION .ldt]
	ALIGN 32
LABEL_LDT:
LABEL_LDT_DESC_CODEA:	Descriptor	0,	CodeALen - 1,	DA_C + DA_32
	LDTLen	equ	$ - LABEL_LDT

	SelectorLDTCodeA	equ	LABEL_LDT_DESC_CODEA-LABEL_LDT + SA_TIL

	[SECTION .la]
	ALIGN 32
	[BITS 32]
LABEL_CODE_A:
	mov ax, SelectorVideo
	mov gs, ax
	mov edi, (80*12+0)*2
	mov ah, 0x0c
	mov al, 'L'
	mov [gs:edi], ax

	jmp SelectorCode16:0

	CodeALen	equ	$-LABEL_CODE_A


core_end:	
