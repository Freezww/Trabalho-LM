.data
	SEVEN_SEGMENTS_RIGHT: .word 0xFFFF0010	# Display de sete segmentos da direita
	SEVEN_SEGMENTS_LEFT: .word 0xFFFF0011		# Display de sete segmentos da esquerda
	KEYBOARD_ADDRESS:  .word 0xFFFF0012		# Endereco para varredura do teclado
	
	# Valores em hexa para acender o terminal
	# Em ordem: 0, 1, 2, 3, ..., ERROR
	SEGMENT_VALUES: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x79
	
	# Codigo das teclas do teclado digital
	# 0xi1 - Linha 1
	# 0xi2 - Linha 2 ...
	KEYBOARD_CODES: .byte 0x11, 0x21, 0x41, 0x81, 0x12, 0x22, 0x42, 0x82, 0x14, 0x24, 0x44, 0x84, 0x18, 0x28, 0x48, 0x88
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
#ERROR: .byte 0x79

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

# --- Alocar acumulador (global) ---
# 1 palavra (4 bytes) para o contador (N)
# 10 palavras (40 bytes) para os 4 floats
# Total = 10 palavras + Contador = 40 Bytes + 4 Bytes
addi   $v0, $zero, 9     # syscall 9 (sbrk)
addi   $a0, $zero, 44    # Alocar 44 bytes
syscall
add  $s0, $v0, $zero   # Salva o endereco base do acumulador em $s0
sw    $zero, 0($s0)	# Inicializa o contador N em 0

MAIN:
	jal CLEAR_ERROR

	# Enderecamento do Display Direito
	lui $s6, 0xFFFF
	ori $s6, $s6, 0x0010

	# Enderecamento do Display Esquerdo
	lui $s7, 0xFFFF
	ori $s7, $s7, 0x0011
		
	MAIN_LOOP:
		# Chama a rotina de scannear o teclado
		jal SCAN
		
		# Verifica se não foi a última tecla pressionada antes
		beq $v0, $s4, MAIN_LOOP
		
		# $s4 recebe a ultima tecla pressionada
		addi $s4, $v0, 0
		
		# Retorno da SCAN
		beq $v0, $zero, MAIN_LOOP	# Nada foi pressionado, voltar para o laco
		
		# Inicializar variaveis de busca
		addi $s2, $zero, 0
		addi $s3, $zero, 10
		
		SEARCH_LOOP:
			beq $s2, $s3, IGNORE_KEY		# Se indice == 10, a tecla nao é um digito (0-9)
	
			# Calcular endereco do Codigo de Tecla a ser comparado
			#la $t3, KEYBOARD_CODES
			lui $t3, 0x1001			# $t3 = Endereco base de KEYBOARD_CODES
			ori $t3, $t3, 0x17
			add $t3, $t3, $s2		# $t3 = Endereco de KEYBOARD_CODES[indice]
			lb $t4, 0($t3)			# $t4 = KEYBOARD_CODES[indice]
			
			IF:
				# Nao guardar valor
				bne  $v0, $t4, END_IF	# Se codigo da tecla lida for igual ao codigo do indice, acende o display
			
			ELSE:
				# Acender display direito com a tecla pressionada
				#la $t5, SEGMENT_VALUES
				lui $t5, 0x1001			# $t5 = Endereco base de SEGMENT_VALUES
				ori $t5, $t5, 0xc
				add $t5, $t5, $s2		# $t5 = Endereco de SEGMENT_VALUES[indice]
				lb $a0, 0($t5)			# $a0 = Valor do display para o digito
			
				# Guardar valor que esta no display
				jal LIGHT_RIGHT_DISPLAY	# Se codigo da tecla lida for igual ao codigo do indice, acende o display
				addi $s1, $s2, 0							# Repassar o valor do display para $s1 - Guardar o numero que esta no display
			
			END_IF:
			addi $s2, $s2, 1			# Incrementa o indice
			j SEARCH_LOOP			# Continua a busca
			
		IGNORE_KEY:
			# $s2 vale 10 quando chega aqui
			# Mudar o valor da constante $s3 para 16
			 addi $s3, $zero, 16
			 
			SEARCH_LOOP_LETTER:
				beq $s2, $s3, END_TREATMENTS		# Se indice == 16, chegamos ao fim da verificacao
			
				# Calcular endereco do Codigo de Tecla a ser comparado
				#la $t3, KEYBOARD_CODES
				lui $t3, 0x1001			# $t3 = Endereco base de KEYBOARD_CODES
				ori $t3, $t3, 0x17
				add $t3, $t3, $s2		# $t3 = Endereco de KEYBOARD_CODES[indice]
				lb $t4, 0($t3)			# $t4 = KEYBOARD_CODES[indice]
	
				beq $v0, $t4, SWITCH_CASE		# Se codigo da tecla lida for igual ao codigo do indice, acende o display
	
				addi $s2, $s2, 1				# Incrementa o indice
				j SEARCH_LOOP_LETTER		# Retorna pois ainda nao encontrou qual letra que e
				
				# Escolha caso
				SWITCH_CASE:
					# Verificacao com a constante 10 (Indica letra A)
					addi $t0, $zero, 10
					beq $s2, $t0, LETTER_A

					# Verificacao com a constante 11 (Indica letra B)
					addi $t0, $zero, 11
					beq $s2, $t0, LETTER_B
					
					# Verificacao com a constante 12 (Indica letra C)
					addi $t0, $zero, 12
					beq $s2, $t0, LETTER_C
					
					# Verificacao com a constante 13 (Indica letra D)
					addi $t0, $zero, 13
					beq $s2, $t0, LETTER_D
					
					# Verificacao com a constante 15 (Indica letra E)
					addi $t0, $zero, 14
					beq $s2, $t0, LETTER_E
					
					# Verificacao com a constante 15 (Indica letra F)
					addi $t0, $zero, 15
					beq $s2, $t0, LETTER_F
					
					j END_TREATMENTS
										
				# Tratar quando 'a' e pressionado
				LETTER_A:
					mtc1  $s1, $f12						# Passa o valor que esta no display como valor que deve ser inserido
					# cvt.s.w $f12, $f12					# Converte a palavra armazenada em $f12 para precisao simples
					jal INSERT_ACCUMULATOR_FLOAT	# Vai para a rotina de insercao no acumulador
					
					j END_TREATMENTS	# Pula para o fim do tratamento das teclas
					
				# Tratar quando 'b' e pressionado
				LETTER_B:
					
					j END_TREATMENTS	# Pula para o fim do tratamento das teclas

				# Tratar quando 'c' e pressionado
				LETTER_C:
					
					j END_TREATMENTS	# Pula para o fim do tratamento das teclas

				# Tratar quando 'd' e pressionado
				LETTER_D:
					
					j END_TREATMENTS	# Pula para o fim do tratamento das teclas
					
				# Tratar quando 'e' e pressionado
				LETTER_E:
					
					j END_TREATMENTS	# Pula para o fim do tratamento das teclas
				
				# Tratar quando 'f' e pressionado
				LETTER_F:
					
					j END_TREATMENTS	# Pula para o fim do tratamento das teclas
															
			END_TREATMENTS:
					
			j MAIN_LOOP
	END_MAIN_LOOP:

	addi $v0, $zero, 10
	syscall
END_MAIN:


#======================================
# Rotina para acender o display esquerdo
# Parametros:
#	$a0 contem o codigo a ser acendido no display
#======================================
LIGHT_LEFT_DISPLAY:
	# Guardar registradores
	sw $s1, 0($sp)
	sw $ra, 4($sp)
	addi $sp, $sp, -8	# Ajusta a pilha para a proxima posicao vazia
	
	# Enderecamento do Display Esquerdo
	lui $s1, 0xFFFF
	ori $s1, $s1, 0x0011

	# Limpar Display antes de colocar novo valor
	jal CLEAR_ERROR

	sb $a0, 0($s1)			# Escreve o valor do display ($t6) no endereco do Display Esquerdo ($s1)

	# Recupera os dados
	addi $sp, $sp, 8	# Volta a pilha para o inicio
	lw $s1, 0($sp)
	lw $ra, 4($sp)

	jr $ra	# Reinicia o ciclo
	
END_LIGHT_LEFT_DISPLAY:


#======================================
# Rotina para acender o display esquerdo
# Parametros:
#	$a0 contem o codigo a ser acendido no display
#======================================
LIGHT_RIGHT_DISPLAY:
	# Guardar registradores
	sw $s1, 0($sp)
	sw $ra, 4($sp)
	addi $sp, $sp, -8	# Ajusta a pilha para a proxima posicao vazia
	
	# Enderecamento do Display Esquerdo
	lui $s1, 0xFFFF
	ori $s1, $s1, 0x0010

	# Limpar Display antes de colocar novo valor
	jal CLEAR_ERROR

	sb $a0, 0($s1)			# Escreve o valor do display ($t6) no endereco do Display Esquerdo ($s1)

	# Recupera os dados
	addi $sp, $sp, 8	# Volta a pilha para o inicio
	lw $s1, 0($sp)
	lw $ra, 4($sp)

	jr $ra	# Reinicia o ciclo
	
END_LIGHT_RIGHT_DISPLAY:


#======================================
# Rotina para acender o display esquerdo
#======================================
LIGHT_RIGHT_DOT_DISPLAY:
	# Guardar registradores
	sw $s1, 0($sp)
	sw $ra, 4($sp)
	addi $sp, $sp, -8	# Ajusta a pilha para a proxima posicao vazia
	
	# Enderecamento do Display Esquerdo
	lui $s1, 0xFFFF
	ori $s1, $s1, 0x0010

	# Limpar Display antes de colocar novo valor
	jal CLEAR_ERROR

	sb $a0, 0($s1)			# Escreve o valor do display ($t6) no endereco do Display Esquerdo ($s1)

	# Recupera os dados
	addi $sp, $sp, 8	# Volta a pilha para o inicio
	lw $s1, 0($sp)
	lw $ra, 4($sp)

	jr $ra	# Reinicia o ciclo
	
END_LIGHT_RIGHT_DOT_DISPLAY:


#======================================
# Rotina para colocar o erro no display
#======================================
LIGHT_ERROR:
	# Guardar registradores que serao usados
	sw $s1, 0($sp)
	sw $s2,-4($sp)
	sw $ra, -8($sp)
	addi $sp, $sp, -12	# Ajusta o $sp para a proxima posicao vazia
	
	# Enderecamento do Display Direito
	lui $s1, 0xFFFF
	ori $s1, $s1, 0x0010

	# Enderecamento do Display Esquerdo
	lui $s2, 0xFFFF
	ori $s2, $s2, 0x0011
	
	# 0x79
	# Gravar no display o valor de erro
	addi $t0, $zero, 0x79
	sb $t0, 0($s1)
	sb $t0, 0($s2)
	
	# Recuperar registradores
	addi $sp, $sp, 12	# Ajusta o $sp para o inicio da pilha
	lw $s1, 0($sp)
	lw $s2,-4($sp)
	lw $ra, -8($sp)
	
	# Retorna para o chamador
	jr $ra
	
END_LIGHT_ERROR:
	
CLEAR_ERROR:
	# Guardar registradores que serao usados
	sw $s1, 0($sp)
	sw $s2,-4($sp)
	sw $ra, -8($sp)
	addi $sp, $sp, -12	# Ajusta o $sp para a proxima posicao vazia
	
	# Enderecamento do Display Direito
	lui $s1, 0xFFFF
	ori $s1, $s1, 0x0010

	# Enderecamento do Display Esquerdo
	lui $s2, 0xFFFF
	ori $s2, $s2, 0x0011
	
	# 0x79
	# Gravar no display o valor de erro
	addi $t0, $zero, 0
	addi $t1, $zero, 0x3F	# Colocar 0 no display direito
	sb $t1, 0($s1)
	sb $t0, 0($s2)
	
	# Recuperar registradores
	addi $sp, $sp, 12	# Ajusta o $sp para o inicio da pilha
	lw $s1, 0($sp)
	lw $s2,-4($sp)
	lw $ra, -8($sp)
	
	# Retorna para o chamador
	jr $ra
	
END_CLEAR_ERROR:


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
	addi $s5, $zero, 9		# Constante 9
	
	SCAN_LOOP:
		sb $s4, 0($s2)		# Faz a varredura na linha 1->2->4->8
		lb $t0, 0($s3)		# Retorna para mim se alguma tecla foi pressionada
		beq $t0, $zero, NEXT_ROW
		
		addi $v0, $t0, 0		# Repassa a tecla pressionada para $v0
		
		j END_SCAN_LOOP
		
		NEXT_ROW:
			# Avancar linha que sera scanneada
			sll $s4, $s4, 1						# Faz um shift a esquerda para mudar a posicao do bit
			slt $t1, $s4, $s5						# $s4 < 9 ? 1 : 0
			beq $t1, $zero, END_SCAN_LOOP		# Varreu todas as linhas
			
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


#===========================================================
# FUNCAO PARA INSERIR FLOAT NO ACUMULADOR
# Argumentos: $f12 (float a inserir), $s0 (acumulador global)
#===========================================================
INSERT_ACCUMULATOR_FLOAT:
	# Guardar $s1 e $fp na pilha
	sw $s1, 0($sp)	# Guarda $s1 em sp[0]
	
	# Ajustar pilha para guardar mais informacoes
	addi $sp, $sp, -4
	
	# Avaliacao da expressao
	lw    $s1, 0($s0)       # $t0 = N (contador atual)
	slti  $t1, $s1, 10       # Verifica se N < 10  (limite do nosso array - 10 floats)
	beq   $t1, $zero, INSERT_ACCUMULATOR_ELSE
	
	# Calculo do deslocamento
	addi $t1, $zero, 4	# $t1 = 4 (bytes por float)
	mul $t2, $s1, $t1	# $t0 * $t1 (N * 4)
	addi $t2, $t2, 4     	# $t2 = offset + 4 (pula o contador)
	add  $t2, $t2, $s0	# $t2 = Endereco Base + offset + 4
	
	# Guarda o valor no acumulador
	swc1  $f12, 0($t2)    # Salva o float no endereco
	addi $s1, $s1, 1	# N++
	sw    $s1, 0($s0)	# Salva o novo N
	
	# Pula para o final da condicao
	beq   $zero, $zero, INSERT_ACCUMULATOR_END_IF
	
	INSERT_ACCUMULATOR_ELSE: # Acumulador cheio
		# Obter string para informar acumulador cheio
		# la $a0, MSG_FULL
		lui $a0, 0x1001
		ori $a0, $a0, 0			# Offset 0 (MSG_FULL)
		addi   $v0, $zero, 4		# syscall para imprimit string
		syscall

		# Obter quebra de linha
		addi $a0, $zero, 10		# Codigo do caractere nova linha
		addi   $v0, $zero, 11
		syscall
		
	INSERT_ACCUMULATOR_END_IF:
		# Recuperar dados da pilha antes de retornar
		lw $s1, 4($sp)	# Obtem de volta o antigo $s1
		addi $sp, $sp, 4	# Retorna $sp para o endereco correto
	
		# Retorna para o chamados
		jr $ra
END_INSERT_ACCUMULATOR_FLOAT:


#===========================================================
# FUNCAO PARA LIMPAR O ACUMULADOR
#===========================================================
CLEAR_ACCUMULATOR:
	sw $zero, 0($s0)
	jr $ra
END_CLEAR_ACCUMULATOR:
