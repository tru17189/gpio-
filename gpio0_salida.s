.global GetGpioAddress
GetGpioAddress:
	gpioAddr .req r0
	push {lr}
	@ldr gpioAddr,=0x20200000
	ldr gpioAddr,=0x3F200000 @GPIO base para raspberry 2
	@modificaciones para utilizar la memoria virtual
	bl phys_to_virt
 	mov r7, r0  @ r7 points to that physical page
 	ldr r6, =myloc
 	str r7, [r6] @ save this 
	pop {pc}
	.unreq gpioAddr

/* NEW
* SetGpioFunction sets the function of the GPIO register addressed by r0 to the
* low  3 bits of r1.
* C++ Signature: void SetGpioFunction(u32 gpioRegister, u32 function)
*/
.global SetGpioFunction
SetGpioFunction:
    pinNum .req r0
    pinFunc .req r1
	cmp pinNum,#53
	cmpls pinFunc,#7
	movhi pc,lr

	push {lr}
	mov r2,pinNum
	.unreq pinNum
	pinNum .req r2
	@bl GetGpioAddress no se llama la funcion sino
	ldr r6, =myloc
 	ldr r0, [r6] @ obtener direccion 	
	gpioAddr .req r0

	functionLoop$:
		cmp pinNum,#9
		subhi pinNum,#10
		addhi gpioAddr,#4
		bhi functionLoop$

	add pinNum, pinNum,lsl #1
	lsl pinFunc,pinNum

	mask .req r3
	mov mask,#7					/* r3 = 111 in binary */
	lsl mask,pinNum				/* r3 = 11100..00 where the 111 is in the same position as the function in r1 */
	.unreq pinNum

	mvn mask,mask				/* r3 = 11..1100011..11 where the 000 is in the same poisiont as the function in r1 */
	oldFunc .req r2
	ldr oldFunc,[gpioAddr]		/* r2 = existing code */
	and oldFunc,mask			/* r2 = existing code with bits for this pin all 0 */
	.unreq mask

	orr pinFunc,oldFunc			/* r1 = existing code with correct bits set */
	.unreq oldFunc

	str pinFunc,[gpioAddr]
	.unreq pinFunc
	.unreq gpioAddr
	pop {pc}

/* NEW
* SetGpio sets the GPIO pin addressed by register r0 high if r1 != 0 and low
* otherwise. 
* C++ Signature: void SetGpio(u32 gpioRegister, u32 value)
*/
.global SetGpio
SetGpio:	
    pinNum .req r0
    pinVal .req r1

	cmp pinNum,#53
	movhi pc,lr
	push {lr}
	mov r2,pinNum	
    .unreq pinNum	
    pinNum .req r2
	@bl GetGpioAddress no se llama la funcion sino
	ldr r6, =myloc
 	ldr r0, [r6] @ obtener direccion 
    gpioAddr .req r0

	pinBank .req r3
	lsr pinBank,pinNum,#5
	lsl pinBank,#2
	add gpioAddr,pinBank
	.unreq pinBank

	and pinNum,#31
	setBit .req r3
	mov setBit,#1
	lsl setBit,pinNum
	.unreq pinNum

	teq pinVal,#0
	.unreq pinVal
	streq setBit,[gpioAddr,#40]
	strne setBit,[gpioAddr,#28]
	.unreq setBit
	.unreq gpioAddr
	pop {pc}
	
EntradaLED: 
	ldr r0, =0x20200000
	bl phys_to_virt
	mov r7, r0
	ldr r6, =myloc
	str r7, [r6]
	
loop: @@entrada para escritura 
	mov r1, #1
	lsl r1, #18
	str r1, [r0, #4]
	
	@@enciende la led
	mov r1, #1
	lsl r1, #16
	str r1, [r0, #40]
	push {r0}
	bl wait 
	pop {r0}
	
	@@apagar la led
	str r1, [r0, #28]
	
	push {r0}
	bl wait 
	pop {r0}
	
	b loop
	
wait:
	mov r0, #0x4000000
sleepLoop:
	subs r0, #1
	bne sleepLoop 
	mov pc, lr
	
	@@entrada al boton 
	mainboton:
	@@utilizando la biblioteca GPIO (gpio0.s)
	bl GetGpioAddress 	
	
	@@GPIO para escritura 
	mov r0,#4
	mov r1,#1
	bl SetGpioFunction

	@GPIO para lectura 
	mov r0,#14
	mov r1,#0
	bl SetGpioFunction
	
	loop:  @@Apagar GPIO 4
	mov r0,#4
	mov r1,#0
	bl SetGpio
	
	ldr r6, =myloc
 	ldr r0, [r6] 		
	ldr r5,[r0,#0x34] 	
	mov r7,#1
	lsl r7,#14
	and r5,r7 	
	
	teq r5,#0
	movne r0,#4		
	movne r1,#1
	blne SetGpio
		
	b loop

	@ salida al sistema operativo
	mov r7,#1
	swi 0
	
	wait:
 mov r0, #0x4000000 
sleepLoop:
 subs r0,#1
 bne sleepLoop 
 mov pc,lr
	
	.data
	.align 2
	myloc:.word 0 
	
	.end 
	
	
	