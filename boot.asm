	core_base_address	equ	0x00040000
	core_start_sector	equ	0x00000001

	mov ax, cs
	mov ss, ax
	mov sp, 0x7c00

	mov eax, [cs:pgdt + 0x7c00+0x02]
	xor edx, edx
	mov ebx, 16
	div ebx

	mov ds, eax
	mov ebx, edx

	mov dword [ebx + 0x08], 0x0000ffff
	mov dword [ebx + 0x0c], 0x00cf9200

	mov dword [ebx + 0x10], 0x7c0001ff
	mov dword [ebx + 0x14], 0x00409800

	mov dword [ebx + 0x18], 0x7c00fffe
	mov dword [ebx + 0x1c], 0x00cf9600

	mov dword [ebx + 0x20], 0x80007fff
	mov dword [ebx + 0x24], 0x0040920b

	mov word [cs:pgdt + 0x7c00], 39
	lgdt [cs:pgdt+0x7c00]
	
	cli
	in al, 0x92
	or al, 0000_0010B
	out 0x92, al
	
	mov eax, cr0
	or eax, 1
	mov cr0, eax
	jmp dword 0x0010:flush

	[bits 32]
flush:
	mov eax, 0x0008
	mov ds, eax

	mov eax, 0x0018
	mov ss, eax
	xor esp, esp

	mov edi, core_base_address
	mov eax, core_start_sector
	mov ebx, edi
	call read_hard_disk_0
	


	jmp	$











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
;----------------------------------------------------------------------------------------
make_gdt_descriptor:                     ;构造描述符
                                         ;输入：EAX=线性基地址
                                         ;      EBX=段界限
                                         ;      ECX=属性（各属性位都在原始
                                         ;      位置，其它没用到的位置0） 
                                         ;返回：EDX:EAX=完整的描述符
         mov edx,eax
         shl eax,16                     
         or ax,bx                        ;描述符前32位(EAX)构造完毕
      
         and edx,0xffff0000              ;清除基地址中无关的位
         rol edx,8
         bswap edx                       ;装配基址的31~24和23~16  (80486+)
      
         xor bx,bx
         or edx,ebx                      ;装配段界限的高4位
      
         or edx,ecx                      ;装配属性 
      
         ret
      
;-------------------------------------------------------------------------------

	pgdt	dw 0
		dd 0x00007e00
	times	510 - ($ - $$)	db 0
				db 0x55, 0xaa
