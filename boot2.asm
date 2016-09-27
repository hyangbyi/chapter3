	core_base_address	equ	0x100

	mov ax, cs
	mov ss, ax
	mov ds, ax
	mov sp, 0x7c00
	
	
	cli
	mov eax, 1
	mov edi, core_base_address
	mov ebx, edi
	call read_hard_disk_0

	mov eax, [edi]
	xor edx, edx
	mov ecx, 512
	div ecx
	or edx, edx
	jnz @1
	dec eax
@1:
	or eax, eax
	jz setup

	mov ecx, eax
	mov eax, 1
	inc eax
@2:
	call read_hard_disk_0
	inc eax
	loop @2

	;mov ax, [di]
	;add ax, core_base_address
	;mov [di], ax
setup:
	jmp far [di+4] 		;b 0x7c4a


;----------------------------------------------------------------------------------------

read_hard_disk_0:                        ;从硬盘读取一个逻辑扇区
                                         ;EAX=逻辑扇区号
                                         ;DS:EBX=目标缓冲区地址
                                         ;返回：EBX=EBX+512 
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                       ;读取的扇区数

         inc dx                          ;0x1f3
         pop eax
         out dx,al                       ;LBA地址7~0

         inc dx                          ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                       ;LBA地址15~8

         inc dx                          ;0x1f5
         shr eax,cl
         out dx,al                       ;LBA地址23~16

         inc dx                          ;0x1f6
         shr eax,cl
         or al,0xe0                      ;第一硬盘  LBA地址27~24
         out dx,al

         inc dx                          ;0x1f7
         mov al,0x20                     ;读命令
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                      ;不忙，且硬盘已准备好数据传输 

         mov ecx,256                     ;总共要读取的字数
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [ebx],ax
         add ebx,2
         loop .readw

         pop edx
         pop ecx
         pop eax
      
         ret
	

	times	510 - ($ - $$)	db	0
				db	0x55, 0xaa
