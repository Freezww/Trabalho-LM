.data
	SEVEN_SEGMENTS_LEFT: .word 0xFFFF0010	# Display de sete segmentos da esquerda
	SEVEN_SEGMENTS_RIGHT: .word 0xFFFF0011	# Display de sete segmentos da direita
	KEYBOARD_ADDRESS:  
	
	# Valores em hexa para acender o terminal
	# Em ordem: 0, 1, 2, 3, ...
	SEGMENT_VALUES: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
	
	# Codigo das teclas do teclado digital
	KEYBOARD_CODES: .byte 0x11, 0x21, 0x41, 0x81, 0x12, 0x22, 0x42, 0x82, 0x14, 0x24	
.text

#ZERO: .byte 0x3F
#ONE: .byte 0x6
#TWO: .byte 0x5B
#THREE: .byte 0x4F
#FOUR: .byte 0x66
#FIVE: .byte 0x6D
#SIX: .byte 0x7D
#SEVEN: .byte 0x7
#EIGHT: .byte 0x7F
#NINE: .byte 0x6F

# Codigo das teclas:
# 0x11 -> 0
# 0x21 -> 1
# 0x41 -> 2
# 0x81 -> 3
# 0x21 -> 4
# 0x22 -> 5
# 0x24 -> 6
# 0x28 -> 7
# 0x41 -> 8
# 0x42 -> 9
# 0x44 -> a
# 0x48 -> b
# 0x81 -> c
# 0x82 -> d
# 0x84 -> e
# 0x88 -> f


MAIN:
	# Enderecamento do display
	lui $s0, 0xFFFF
	ori $s0, $s0, 0x0011
	
	MAIN_LOOP:
		# Chama a rotina de scannear o teclado
		jal SCAN
		
		# Retorno da SCAN
		beq $v0, $zero, MAIN_LOOP	# Nada foi pressionado, voltar para o laco
		
		# Inicializar variaveis de busca
		addi $t1, $zero, 0
		addi $t2, $zero, 10
		
		SEARCH_LOOP:
			beq $t1, $t2, IGNORAR_TECLA		# Se indice == 10, a tecla nao é um digito (0-9)
	
			# Calcular endereco do Codigo de Tecla a ser comparado
			# la $t3, KEYBOARD_CODES
			lui $t3, 0x1001			# $t3 = Endereco base de KEY_CODES
			ori $t3, $t3, 0x12
			add $t3, $t3, $t1		# $t3 = Endereco de KEY_CODES[indice]
			lb $t4, 0($t3)			# $t4 = KEY_CODES[indice]
	
			beq $v0, $t4, ACENDER_DISPLAY	# Se codigo da tecla lida for igual ao codigo do indice, acende o display!
	
			addi $t1, $t1, 1			# Incrementa o indice
			j SEARCH_LOOP			# Continua a busca
		
		ACENDER_DISPLAY:
			# $t1 contem o indice correto (0 a 9)
			#la $t5, SEGMENT_VALUES
			lui $t5, 0x1001			# $t5 = Endereco base de SEGMENT_VALUES
			ori $t5, $t5, 0x8
			add $t5, $t5, $t1		# $t5 = Endereco de SEGMENT_VALUES[indice]
			lb $t6, 0($t5)			# $t6 = Valor do display para o digito

			sb $t6, 0($s0)			# Escreve o valor do display ($t6) no endereco do Display Direito ($s0)

			j MAIN_LOOP			# Reinicia o ciclo
			
		IGNORAR_TECLA:
			# Se a tecla nao for numerica
			j MAIN_LOOP
	END_MAIN_LOOP:

	addi $v0, $zero, 10
	syscall
FIM_MAIN:

#======================================
# Rotina de scan para teclado digital
# Parametros:
#	Nao recebe nada
# Retorno:
#	# Retorna em $v0 se alguma tecla foi pressionada
#======================================
SCAN:
	# Guardar valor dos registradores
	sw $s1, 0($sp)
	sw $s2, -4($sp)
	sw $s3, -8($sp)
	sw $s4, -12($sp)
	sw $s5, -16($sp)
	sw $ra, -20($sp)
	addi $sp, $sp, -24	# Faz $sp apontar para a proxima posicao vazia

	# Valor de retorno nulo
	addi $v0, $zero, 0

	# Carregar endereços
	lui $s1, 0xFFFF			# Carregar 0xFFFF0000
	ori  $s2, $s1, 0x0012	# Carregar 0xFFFF0012 - Endereço da varredura no teclado
	ori $s3, $s1, 0x0014	# Carrega 0xFFFF0014 - Endereço que guarda se uma tecla foi pressionada no teclado (Valor diferente de zero quando pressionada)
	
	# Scan das linhas
	addi $s4, $zero, 0x1	# Passa o valor 1 para scannear a primeira linha
	addi $s5, $zero, 8		# Constante 8
	
	SCAN_LOOP:
		sb $s4, 0($s2)		# Faz a varredura na linha 1->2->4->8
		lb $t0, 0($s3)		# Retorna para mim se alguma tecla foi pressionada
		beq $t0, $zero, NEXT_ROW
		
		addi $v0, $t0, 0		# Repassa a tecla pressionada para $v0
		
		j END_SCAN_LOOP
		
		NEXT_ROW:
			# Avancar linha que sera scanneada
			sll $s4, $s4, 1						# Faz um shift a esquerda para mudar a posicao do bit
			beq $s4, $s5, END_SCAN_LOOP		# Varreu todas as linhas
			
			j SCAN_LOOP						# Nenhuma tecla foi pressionada e nem as 4 linhas varridas, reinicia a varredura
		END_NEXT_ROW:
	END_SCAN_LOOP:

	# Recuperar dados na pilha antes de retornar
	addi $sp, $sp, 24	# Retorna para o inicio da pilha
	lw $s1, 0($sp)
	lw $s2, -4($sp)
	lw $s3, -8($sp)
	lw $s4, -12($sp)
	lw $s5, -16($sp)
	lw $ra, -20($sp)
	
	# Retorna para o chamador
	jr $ra
END_SCAN: