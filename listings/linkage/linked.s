
./linked:     file format elf64-x86-64


Disassembly of section .init:

0000000000001000 <_init>:
    1000:	f3 0f 1e fa          	endbr64
    1004:	48 83 ec 08          	sub    $0x8,%rsp
    1008:	48 8b 05 d9 2f 00 00 	mov    0x2fd9(%rip),%rax        # 3fe8 <__gmon_start__@Base>
    100f:	48 85 c0             	test   %rax,%rax
    1012:	74 02                	je     1016 <_init+0x16>
    1014:	ff d0                	call   *%rax
    1016:	48 83 c4 08          	add    $0x8,%rsp
    101a:	c3                   	ret

Disassembly of section .plt:

0000000000001020 <.plt>:
    1020:	ff 35 82 2f 00 00    	push   0x2f82(%rip)        # 3fa8 <_GLOBAL_OFFSET_TABLE_+0x8>
    1026:	ff 25 84 2f 00 00    	jmp    *0x2f84(%rip)        # 3fb0 <_GLOBAL_OFFSET_TABLE_+0x10>
    102c:	0f 1f 40 00          	nopl   0x0(%rax)
    1030:	f3 0f 1e fa          	endbr64
    1034:	68 00 00 00 00       	push   $0x0
    1039:	e9 e2 ff ff ff       	jmp    1020 <_init+0x20>
    103e:	66 90                	xchg   %ax,%ax
    1040:	f3 0f 1e fa          	endbr64
    1044:	68 01 00 00 00       	push   $0x1
    1049:	e9 d2 ff ff ff       	jmp    1020 <_init+0x20>
    104e:	66 90                	xchg   %ax,%ax

Disassembly of section .plt.got:

0000000000001050 <wrap_printf@plt>:
    1050:	f3 0f 1e fa          	endbr64
    1054:	ff 25 7e 2f 00 00    	jmp    *0x2f7e(%rip)        # 3fd8 <wrap_printf@Base>
    105a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000001060 <wrap_getpid@plt>:
    1060:	f3 0f 1e fa          	endbr64
    1064:	ff 25 76 2f 00 00    	jmp    *0x2f76(%rip)        # 3fe0 <wrap_getpid@Base>
    106a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000001070 <__cxa_finalize@plt>:
    1070:	f3 0f 1e fa          	endbr64
    1074:	ff 25 7e 2f 00 00    	jmp    *0x2f7e(%rip)        # 3ff8 <__cxa_finalize@GLIBC_2.2.5>
    107a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

Disassembly of section .plt.sec:

0000000000001080 <fprintf@plt>:
    1080:	f3 0f 1e fa          	endbr64
    1084:	ff 25 2e 2f 00 00    	jmp    *0x2f2e(%rip)        # 3fb8 <fprintf@GLIBC_2.2.5>
    108a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

0000000000001090 <sleep@plt>:
    1090:	f3 0f 1e fa          	endbr64
    1094:	ff 25 26 2f 00 00    	jmp    *0x2f26(%rip)        # 3fc0 <sleep@GLIBC_2.2.5>
    109a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)

Disassembly of section .text:

00000000000010a0 <_start>:
    10a0:	f3 0f 1e fa          	endbr64
    10a4:	31 ed                	xor    %ebp,%ebp
    10a6:	49 89 d1             	mov    %rdx,%r9
    10a9:	5e                   	pop    %rsi
    10aa:	48 89 e2             	mov    %rsp,%rdx
    10ad:	48 83 e4 f0          	and    $0xfffffffffffffff0,%rsp
    10b1:	50                   	push   %rax
    10b2:	54                   	push   %rsp
    10b3:	45 31 c0             	xor    %r8d,%r8d
    10b6:	31 c9                	xor    %ecx,%ecx
    10b8:	48 8d 3d ca 00 00 00 	lea    0xca(%rip),%rdi        # 1189 <main>
    10bf:	ff 15 03 2f 00 00    	call   *0x2f03(%rip)        # 3fc8 <__libc_start_main@GLIBC_2.34>
    10c5:	f4                   	hlt
    10c6:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    10cd:	00 00 00 

00000000000010d0 <deregister_tm_clones>:
    10d0:	48 8d 3d 39 2f 00 00 	lea    0x2f39(%rip),%rdi        # 4010 <__TMC_END__>
    10d7:	48 8d 05 32 2f 00 00 	lea    0x2f32(%rip),%rax        # 4010 <__TMC_END__>
    10de:	48 39 f8             	cmp    %rdi,%rax
    10e1:	74 15                	je     10f8 <deregister_tm_clones+0x28>
    10e3:	48 8b 05 e6 2e 00 00 	mov    0x2ee6(%rip),%rax        # 3fd0 <_ITM_deregisterTMCloneTable@Base>
    10ea:	48 85 c0             	test   %rax,%rax
    10ed:	74 09                	je     10f8 <deregister_tm_clones+0x28>
    10ef:	ff e0                	jmp    *%rax
    10f1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    10f8:	c3                   	ret
    10f9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000001100 <register_tm_clones>:
    1100:	48 8d 3d 09 2f 00 00 	lea    0x2f09(%rip),%rdi        # 4010 <__TMC_END__>
    1107:	48 8d 35 02 2f 00 00 	lea    0x2f02(%rip),%rsi        # 4010 <__TMC_END__>
    110e:	48 29 fe             	sub    %rdi,%rsi
    1111:	48 89 f0             	mov    %rsi,%rax
    1114:	48 c1 ee 3f          	shr    $0x3f,%rsi
    1118:	48 c1 f8 03          	sar    $0x3,%rax
    111c:	48 01 c6             	add    %rax,%rsi
    111f:	48 d1 fe             	sar    $1,%rsi
    1122:	74 14                	je     1138 <register_tm_clones+0x38>
    1124:	48 8b 05 c5 2e 00 00 	mov    0x2ec5(%rip),%rax        # 3ff0 <_ITM_registerTMCloneTable@Base>
    112b:	48 85 c0             	test   %rax,%rax
    112e:	74 08                	je     1138 <register_tm_clones+0x38>
    1130:	ff e0                	jmp    *%rax
    1132:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1138:	c3                   	ret
    1139:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000001140 <__do_global_dtors_aux>:
    1140:	f3 0f 1e fa          	endbr64
    1144:	80 3d dd 2e 00 00 00 	cmpb   $0x0,0x2edd(%rip)        # 4028 <completed.0>
    114b:	75 2b                	jne    1178 <__do_global_dtors_aux+0x38>
    114d:	55                   	push   %rbp
    114e:	48 83 3d a2 2e 00 00 	cmpq   $0x0,0x2ea2(%rip)        # 3ff8 <__cxa_finalize@GLIBC_2.2.5>
    1155:	00 
    1156:	48 89 e5             	mov    %rsp,%rbp
    1159:	74 0c                	je     1167 <__do_global_dtors_aux+0x27>
    115b:	48 8b 3d a6 2e 00 00 	mov    0x2ea6(%rip),%rdi        # 4008 <__dso_handle>
    1162:	e8 09 ff ff ff       	call   1070 <__cxa_finalize@plt>
    1167:	e8 64 ff ff ff       	call   10d0 <deregister_tm_clones>
    116c:	c6 05 b5 2e 00 00 01 	movb   $0x1,0x2eb5(%rip)        # 4028 <completed.0>
    1173:	5d                   	pop    %rbp
    1174:	c3                   	ret
    1175:	0f 1f 00             	nopl   (%rax)
    1178:	c3                   	ret
    1179:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000001180 <frame_dummy>:
    1180:	f3 0f 1e fa          	endbr64
    1184:	e9 77 ff ff ff       	jmp    1100 <register_tm_clones>

0000000000001189 <main>:
    1189:	f3 0f 1e fa          	endbr64
    118d:	55                   	push   %rbp
    118e:	48 89 e5             	mov    %rsp,%rbp
    1191:	48 83 ec 10          	sub    $0x10,%rsp
    1195:	48 8b 05 84 2e 00 00 	mov    0x2e84(%rip),%rax        # 4020 <stderr@GLIBC_2.2.5>
    119c:	48 8b 15 3d 2e 00 00 	mov    0x2e3d(%rip),%rdx        # 3fe0 <wrap_getpid@Base>
    11a3:	48 8d 0d 5a 0e 00 00 	lea    0xe5a(%rip),%rcx        # 2004 <_IO_stdin_used+0x4>
    11aa:	48 89 ce             	mov    %rcx,%rsi
    11ad:	48 89 c7             	mov    %rax,%rdi
    11b0:	b8 00 00 00 00       	mov    $0x0,%eax
    11b5:	e8 c6 fe ff ff       	call   1080 <fprintf@plt>
    11ba:	48 8b 05 5f 2e 00 00 	mov    0x2e5f(%rip),%rax        # 4020 <stderr@GLIBC_2.2.5>
    11c1:	48 8b 15 10 2e 00 00 	mov    0x2e10(%rip),%rdx        # 3fd8 <wrap_printf@Base>
    11c8:	48 8d 0d 52 0e 00 00 	lea    0xe52(%rip),%rcx        # 2021 <_IO_stdin_used+0x21>
    11cf:	48 89 ce             	mov    %rcx,%rsi
    11d2:	48 89 c7             	mov    %rax,%rdi
    11d5:	b8 00 00 00 00       	mov    $0x0,%eax
    11da:	e8 a1 fe ff ff       	call   1080 <fprintf@plt>
    11df:	bf 01 00 00 00       	mov    $0x1,%edi
    11e4:	e8 a7 fe ff ff       	call   1090 <sleep@plt>
    11e9:	b8 00 00 00 00       	mov    $0x0,%eax
    11ee:	e8 6d fe ff ff       	call   1060 <wrap_getpid@plt>
    11f3:	89 45 fc             	mov    %eax,-0x4(%rbp)
    11f6:	8b 45 fc             	mov    -0x4(%rbp),%eax
    11f9:	89 c6                	mov    %eax,%esi
    11fb:	48 8d 05 3c 0e 00 00 	lea    0xe3c(%rip),%rax        # 203e <_IO_stdin_used+0x3e>
    1202:	48 89 c7             	mov    %rax,%rdi
    1205:	b8 00 00 00 00       	mov    $0x0,%eax
    120a:	e8 41 fe ff ff       	call   1050 <wrap_printf@plt>
    120f:	b8 00 00 00 00       	mov    $0x0,%eax
    1214:	c9                   	leave
    1215:	c3                   	ret

Disassembly of section .fini:

0000000000001218 <_fini>:
    1218:	f3 0f 1e fa          	endbr64
    121c:	48 83 ec 08          	sub    $0x8,%rsp
    1220:	48 83 c4 08          	add    $0x8,%rsp
    1224:	c3                   	ret
