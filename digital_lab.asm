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
	.align 1
	
	VECTOR: .space 400
	
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
	# Vai para o laco do programa
	jal READ_KEYBOARD
	
	# Encerra o programa
	addi $v0, $zero, 10
	syscall
END_MAIN:


#======================================
# Rotina para varredura do teclado
#======================================
READ_KEYBOARD:
	# Guardar registradores
	sw $ra, 0($sp)
	sw $s1, -4($sp)
	sw $s2, -8($sp)
	sw $s3, -12($sp)
	sw $s4, -16($sp)
	sw $s5, -20($sp)
    	addi $sp, $sp, -24

	addi $s6, $zero, 0    # Valor decimal atual = 0
	addi $s7, $zero, 1    # Nenhuma tecla pressionada (liberada)
	addi $s1, $zero, 1	# Sinaliza tecla de funcao foi pressionada

	READ_KEYBOARD_LOOP:
    		# Chama SCAN (retorna em $v0 o código da tecla)
    		jal SCAN
    		
    		# Guarda em $s5 o retorno de SCAN
		addi $s5, $v0, 0
    		
    		# Ignora repetição se a tecla anterior ainda estiver pressionada
		beq $s7, $zero, END_READ_KEYBOARD

		# Se nada foi pressionado, sai
	    	beq $s5, $zero, END_READ_KEYBOARD

	    	# Se mesma tecla e ainda nao liberou, ignora
		# beq $s5, $s4, END_READ_KEYBOARD
    	
	    	# Atualiza tecla atual e marca que ha tecla pressionada
		addi $s4, $s5, 0
		addi $s7, $zero, 0   # tecla pressionada

    		# Inicializa busca
	    	addi $s2, $zero, 0     	# indice atual
	    	addi $s3, $zero, 10  	# limite (numeros)

		SEARCH_LOOP:
	    		beq $s2, $s3, IGNORE_KEY
		
	    		# Carrega KEYBOARD_CODES[s2]
		    	# la $t3, KEYBOARD_CODES
		    	lui $t3, 0x1001			# $t3 = Endereco base de KEYBOARD_CODES
			ori $t3, $t3, 0x17
		    	add $t3, $t3, $s2
		    	lb $t4, 0($t3)

		    	# Comparar codigo
			bne $s5, $t4, NEXT_DIGIT	#  Ignorar tecla
			
			IF_CLEAR_DISPLAY:
				beq $s1, $zero, END_IF_CLEAR_DISPLAY		# Nenhuma tecla de funcao foi pressionada anteriormente
				jal CLEAR_DISPLAY			# Limpa o display
				addi $s1, $zero, 0			# Nenhuma tecla de funcao pressionada
				j END_IF_CLEAR_DISPLAY	# Sai do if
			
			END_IF_CLEAR_DISPLAY:	
			
			# Mostra numero no display direito e desloca o anterior para a esquerda
			# Carrega valor do segmento correspondente
			lui $t5, 0x1001
			ori $t5, $t5, 0xc
			add $t5, $t5, $s2
			lb $a0, 0($t5)          # $a0 = codigo 7-seg do digito atual

			# Move display direito -> esquerdo
			jal MOVE_RIGHT_TO_LEFT_DISPLAY

			# Mostra novo valor à direita
			jal LIGHT_RIGHT_DISPLAY

			# Atualiza valor decimal no registrador $s6
			# $s6 = ($s6 % 10) * 10 + novo_digito
			addi $t9, $zero, 10
			div $s6, $t9
			mfhi $t7
			addi $t0, $zero, 10
			mul $t7, $t7, $t0
			add $s6, $t7, $s2    # $s2 contem o indice do digito pressionado (0–9)
		
	    		j END_READ_KEYBOARD

			NEXT_DIGIT:
			    	addi $s2, $s2, 1
			    	j SEARCH_LOOP

			IGNORE_KEY:
			    	# Verificar letras (A–F)
			    	addi $s3, $zero, 16

				SEARCH_LOOP_LETTER:
			    		beq $s2, $s3, END_READ_KEYBOARD

				    	# la $t3, KEYBOARD_CODES
				    	lui $t3, 0x1001			# $t3 = Endereco base de KEYBOARD_CODES
					ori $t3, $t3, 0x17
				    	add $t3, $t3, $s2
				    	lb $t4, 0($t3)
				    	bne $s5, $t4, NEXT_LETTER

				    	# Tratamento de letras
			    		addi $t0, $zero, 10
				    	beq $s2, $t0, LETTER_A

			    		addi $t0, $zero, 11
				    	beq $s2, $t0, LETTER_B

				    	addi $t0, $zero, 12
				    	beq $s2, $t0, LETTER_C

				    	addi $t0, $zero, 13
				    	beq $s2, $t0, LETTER_D

				    	addi $t0, $zero, 14
				    	beq $s2, $t0, LETTER_E

				    	addi $t0, $zero, 15
				    	beq $s2, $t0, LETTER_F
	
				    	j END_READ_KEYBOARD

					NEXT_LETTER:
					    	addi $s2, $s2, 1
					    	j SEARCH_LOOP_LETTER

				# --- Letras ---
				LETTER_A:
					addi $s1, $zero, 1	# Tecla de funcao pressionada
				
			    		mtc1 $s6, $f12
			    		cvt.s.w	$f12, $f12
			    		
			    		jal INSERT_ACCUMULATOR_FLOAT
			    		j END_READ_KEYBOARD

				LETTER_B:
					addi $s1, $zero, 1	# Tecla de funcao pressionada
				
					jal CALCULA_MEDIA		# Calcular a media (retorno em $f0)
					
					mov.s $f12, $f0
					addi $v0, $zero, 2
					syscall
					
					# Atribui o retorno para $f4
					mov.s $f4, $f0
					
					# Carregar um imediato 10 para ponto flutuante
					addi $t0, $zero, 10
					mtc1 $t0, $f5		# Move para o registrador de ponto flutuante
					cvt.s.w $f5, $f5		# Converte o imediato em ponto flutuante

					# Comparar o valor de retorno com 10 (<)
					c.le.s $f5, $f4	# Verifica se o retorno e >= 10
					bc1t F_ERROR		# Desvia e acende erro no display
					
					# Obter a parte inteira do valor
					cvt.w.s $f6, $f4	# Trunca o ponto flutuante em um inteiro
					mfc1 $t0, $f6	# Repassa para um registrador inteiro
					
					# Exibe digito da Esquerda
					lui $t5, 0x1001
					ori $t5, $t5, 0xc		# Endereco base de SEGMENT_VALUES
					add $t5, $t5, $t0	# Adiciona o indice do digito
					lb $a0, 0($t5)		# Carrega o codigo 7-seg em $a0
					jal LIGHT_LEFT_DISPLAY
				
					# Acende o ponto no display esquerdo
					jal LIGHT_LEFT_DOT_DISPLAY
					
					# Obter a casa a direita da virgula
					cvt.s.w $f6, $f6		# Converte $f6 novamente para um ponto flutuante
					sub.s $f7, $f4, $f6	# Subtrai (n_real - n_inteiro)
					mul.s $f7, $f7, $f5	# Multiplica a parte com virgula por 10
					
					# Obter a parte inteira do valor
					cvt.w.s $f6, $f7	# Trunca o ponto flutuante em um inteiro
					mfc1 $t0, $f6	# Repassa para um registrador inteiro
					
					# Exibe digito da Direita
					lui $t5, 0x1001
					ori $t5, $t5, 0xc		# Endereco base de SEGMENT_VALUES
					add $t5, $t5, $t0	# Adiciona o indice do digito
					lb $a0, 0($t5)		# Carrega o codigo 7-seg em $a0
					jal LIGHT_RIGHT_DISPLAY
				
					j END_READ_KEYBOARD
				
				LETTER_C:
					addi $s1, $zero, 1	# Tecla de funcao pressionada
				
					jal CALCULA_DESVIO_PADRAO		# Calcular o desvio padrao (retorno em $f0)
					
					mov.s $f12, $f0
					addi $v0, $zero, 2
					syscall
					
					# Atribui o retorno para $f4
					mov.s $f4, $f0
					
					# Carregar um imediato 10 para ponto flutuante
					addi $t0, $zero, 10
					mtc1 $t0, $f5		# Move para o registrador de ponto flutuante
					cvt.s.w $f5, $f5		# Converte o imediato em ponto flutuante

					# Comparar o valor de retorno com 10 (<)
					c.le.s $f5, $f4	# Verifica se o retorno e >= 10
					bc1t F_ERROR		# Desvia e acende erro no display
					
					# Obter a parte inteira do valor
					cvt.w.s $f6, $f4	# Trunca o ponto flutuante em um inteiro
					mfc1 $t0, $f6	# Repassa para um registrador inteiro
					
					# Exibe digito da Esquerda
					lui $t5, 0x1001
					ori $t5, $t5, 0xc		# Endereco base de SEGMENT_VALUES
					add $t5, $t5, $t0	# Adiciona o indice do digito
					lb $a0, 0($t5)		# Carrega o codigo 7-seg em $a0
					jal LIGHT_LEFT_DISPLAY
				
					# Acende o ponto no display esquerdo
					jal LIGHT_LEFT_DOT_DISPLAY
					
					# Obter a casa a direita da virgula
					cvt.s.w $f6, $f6		# Converte $f6 novamente para um ponto flutuante
					sub.s $f7, $f4, $f6	# Subtrai (n_real - n_inteiro)
					mul.s $f7, $f7, $f5	# Multiplica a parte com virgula por 10
					
					# Obter a parte inteira do valor
					cvt.w.s $f6, $f7	# Trunca o ponto flutuante em um inteiro
					mfc1 $t0, $f6	# Repassa para um registrador inteiro
					
					# Exibe digito da Direita
					lui $t5, 0x1001
					ori $t5, $t5, 0xc		# Endereco base de SEGMENT_VALUES
					add $t5, $t5, $t0	# Adiciona o indice do digito
					lb $a0, 0($t5)		# Carrega o codigo 7-seg em $a0
					jal LIGHT_RIGHT_DISPLAY
				
					j END_READ_KEYBOARD
				
				LETTER_D:
					addi $s1, $zero, 1	# Tecla de funcao pressionada
				
					add $a0, $s6, $zero	# Passa o numero digitado ($s6) como argumento $a0 (move)
					jal CALCULA_VAN_ECK	# $v0 = van_eck(n)

					# Tratar retorno
					addi $t0, $zero, 100
					slt $t1, $v0, $t0	# $t1 = 1 se $v0 < 100, 0 caso contrario
					beq $t1, $zero, F_ERROR	# Se $v0 >= 100, pula para o erro
					
					# Se $v0 < 100, exibir nos displays
					addi $t0, $zero, 10
					div $v0, $t0		# Divide $v0 por 10
					mflo $t1		# $t1 = Quociente (Dezena / Display Esquerdo)
					mfhi $t2		# $t2 = Resto (Unidade / Display Direito)

					# Exibe digito da Esquerda (Quociente)
					lui $t5, 0x1001
					ori $t5, $t5, 0xc		# Endereco base de SEGMENT_VALUES
					add $t5, $t5, $t1	# Adiciona o indice do digito
					lb $a0, 0($t5)		# Carrega o codigo 7-seg em $a0
					jal LIGHT_LEFT_DISPLAY
					
					# Exibe digito da Direita (Resto)
					lui $t5, 0x1001
					ori $t5, $t5, 0xc	# Endereco base de SEGMENT_VALUES
					add $t5, $t5, $t2	# Adiciona o indice do digito
					lb $a0, 0($t5)		# Carrega o codigo 7-seg em $a0
					jal LIGHT_RIGHT_DISPLAY
					
					j F_END
						
				LETTER_E:
					addi $s1, $zero, 1	# Tecla de funcao pressionada
				
					add $a0, $s6, $zero	# Passa o numero digitado ($s6) como argumento $a0 (move)
					jal PROC_FIBONACCI	# $v0 = van_eck(n)

					# Tratar retorno
					addi $t0, $zero, 100
					slt $t1, $v0, $t0	# $t1 = 1 se $v0 < 100, 0 caso contrario
					beq $t1, $zero, F_ERROR	# Se $v0 >= 100, pula para o erro
					
					# Se $v0 < 100, exibir nos displays
					addi $t0, $zero, 10
					div $v0, $t0		# Divide $v0 por 10
					mflo $t1		# $t1 = Quociente (Dezena / Display Esquerdo)
					mfhi $t2		# $t2 = Resto (Unidade / Display Direito)

					# Exibe digito da Esquerda (Quociente)
					lui $t5, 0x1001
					ori $t5, $t5, 0xc		# Endereco base de SEGMENT_VALUES
					add $t5, $t5, $t1	# Adiciona o indice do digito
					lb $a0, 0($t5)		# Carrega o codigo 7-seg em $a0
					jal LIGHT_LEFT_DISPLAY
					
					# Exibe digito da Direita (Resto)
					lui $t5, 0x1001
					ori $t5, $t5, 0xc	# Endereco base de SEGMENT_VALUES
					add $t5, $t5, $t2	# Adiciona o indice do digito
					lb $a0, 0($t5)		# Carrega o codigo 7-seg em $a0
					jal LIGHT_RIGHT_DISPLAY
					
					j F_END
					
				LETTER_F:
					addi $s1, $zero, 1	# Tecla de funcao pressionada
					addi $s6, $zero, 0	# Zera o valor decimal
					
					jal CLEAR_ALL
					
					j END_READ_KEYBOARD
					
				F_END:
					addi $s6, $zero, 0	# Reseta o numero atual
					j END_READ_KEYBOARD

				F_ERROR:
					jal LIGHT_ERROR
					j END_READ_KEYBOARD
					
				# Guardar a ultima tecla pressionada
				# add $s1, $s5, 0
			
				# Voltar ao inicio do laco
				 j END_READ_KEYBOARD
	 
END_READ_KEYBOARD:
	# Se nenhuma tecla for detectada, marca como liberada
	beq $s5, $zero, KEY_RELEASED
	j END_KEY_RELEASE

	KEY_RELEASED:
		addi $s4, $zero, 0	# Ultima tecla pressionada foi 0 (liberou)
		addi $s7, $zero, 1   	# Tecla liberada

	END_KEY_RELEASE:
		addi $v0, $zero, 32   # syscall 32 (sleep)
		addi $a0, $zero, 100   # 20 milissegundos
		syscall
		j READ_KEYBOARD_LOOP
				
	# Recuperar os valores armazenados
    	addi $sp, $sp, 24
	lw $ra, 0($sp)
	lw $s1, -4($sp)
	lw $s2, -8($sp)
	lw $s3, -12($sp)
	lw $s4, -16($sp)
	lw $s5, -20($sp)
	
	# Retorna para o chamador
    	jr $ra


#======================================
# MOVE_RIGHT_TO_LEFT_DISPLAY
# Copia o valor do display direito para o esquerdo
#======================================
MOVE_RIGHT_TO_LEFT_DISPLAY:
    # Guardar registradores
    sw $s1, 0($sp)
    sw $s2, -4($sp)
    sw $ra, -8($sp)
    addi $sp, $sp, -12

    # Endereços dos displays
    lui $s1, 0xFFFF
    ori $s1, $s1, 0x0010   # Display direito
    lui $s2, 0xFFFF
    ori $s2, $s2, 0x0011   # Display esquerdo

    lb $t0, 0($s1)         # le o valor atual do display direito
    sb $t0, 0($s2)         # escreve no display esquerdo

    # Restaurar registradores
    addi $sp, $sp, 12
    lw $s1, 0($sp)
    lw $s2, -4($sp)
    lw $ra, -8($sp)

    jr $ra
END_MOVE_RIGHT_TO_LEFT_DISPLAY:


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
LIGHT_LEFT_DOT_DISPLAY:
	# Guardar registradores
	sw $s1, 0($sp)
	sw $ra, 4($sp)
	addi $sp, $sp, -8	# Ajusta a pilha para a proxima posicao vazia
	
	# Enderecamento do Display Esquerdo
	lui $s1, 0xFFFF
	ori $s1, $s1, 0x0011
	
	lb $t0, 0($s1)
	addi $t0, $t0, 0x80		# Codigo 7-seg do ponto
	sb $t0, 0($s1)				# Escreve o valor do display ($t6) no endereco do Display Esquerdo ($s1)

	# Recupera os dados
	addi $sp, $sp, 8	# Volta a pilha para o inicio
	lw $s1, 0($sp)
	lw $ra, 4($sp)

	jr $ra	# Reinicia o ciclo
	
END_LIGHT_LEFT_DOT_DISPLAY:


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


#======================================
# Rotina para limpar o display
#======================================
CLEAR_DISPLAY:
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
	sb $t0, 0($s1)
	sb $t0, 0($s2)
	
	# Recuperar registradores
	addi $sp, $sp, 12	# Ajusta o $sp para o inicio da pilha
	lw $s1, 0($sp)
	lw $s2,-4($sp)
	lw $ra, -8($sp)
	
	# Retorna para o chamador
	jr $ra
	
END_CLEAR_DISPLAY:


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
			
			# Dar um "respiro" para o programa
			#addi $v0, $zero, 32   # syscall 32 (sleep)
    			#addi $a0, $zero, 2    # 2 milissegundo
    			#syscall
			
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


#===========================================================
# FUNCAO PARA CALCULAR O N-ESIMO TERMO DE VAN ECK
#===========================================================
CALCULA_VAN_ECK:
# armazenar na pilha
addi $sp, $sp, -40
sw $ra, 0($sp) 
sw $a0, 4($sp) # armazena $a0 (n)
sw $s0, 8($sp)
sw $s1, 12($sp)
sw $s2, 16($sp)
sw $s3, 20($sp)
sw $s4, 24($sp)
sw $s5, 28($sp)
sw $s6, 32($sp)
sw $s7, 36($sp)

# caso base 
slti $t0, $a0, 1 # verifica se n < 1 (ou seja, n == 0)
bne $t0,$zero, CASO_BASE
j FIM_IF_BASE

# seq[0] = 0
CASO_BASE:
lui $t5, 0x1001
ori $t5, $t5, 0x0000 
sw $zero, 0($t5) #seq[0] = 0

# Restaura $ra e $s0-$s7
lw $ra, 0($sp) 
lw $s0, 8($sp)
lw $s1, 12($sp)
lw $s2, 16($sp)
lw $s3, 20($sp)
lw $s4, 24($sp)
lw $s5, 28($sp)
lw $s6, 32($sp)
lw $s7, 36($sp)
# Libera o espaco da pilha (40 bytes)
addi $sp, $sp, 40

# return 0
addi $v0, $zero,0
jr $ra

FIM_IF_BASE:
###########################################################################################################
# calculo do termo anterior
addi $a0, $a0, -1 # passa n agora com n - 1
jal CALCULA_VAN_ECK # chama a funcao recursivamente

# puxar da memoria
lw $a0, 4($sp) # recupero o n antigo

addi $s1, $v0, 0 # $s1 = retorno da funcao para n-1 (termo anterior)

################################################################################################################
# procurar ultima vez que $s1 (termo anterior) apareceu
addi $s2, $a0, -2 # indice de busca 'k', comeca em n-2
addi $s3, $zero, 0 # flag para dizer se encontrou (0 = nao, 1 = sim)
addi $s4, $zero, 0 # ultimo indice encontrado

LOOP_BUSCA:
slti $t9, $s2, 0 # verifica se o indice $s2 e menor que 0
bne $t9, $zero, FIM_BUSCA # Se $s2 < 0, termina a busca

# calcular endereco base de seq
lui  $t5, 0x1001
ori  $t5, $t5, 0x0028

sll $t6, $s2, 2 # t6 = indice * 4
add $t7, $t5, $t6 # t7 = endereco de seq[k]
lw $t8, 0($t7) # t8 = seq[k]

beq $t8, $s1, ENCONTROU # verifica se seq[k] == termo anterior, achou
addi $s2, $s2, -1 # indice = indice - 1
j LOOP_BUSCA # fica em loop ate encontrar ou ate chegar em um valor menor que 0

ENCONTROU:  
addi $s4, $s2, 0 # $s4 = indice encontrado (k)
addi $s3, $zero, 1 # flag = 1, achou
j FIM_BUSCA 

################################################################################################################
FIM_BUSCA:
# calcular para o n-esimo termo 
beq $s3, $zero, NAO_ENCONTROU # se nao encontrou (flag=0), salta para nao encontrou

# Se encontrou:
addi $t3, $a0, -1 # t3 = n - 1
sub $v0, $t3, $s4 # a(n) = (n-1) - k
j SALVAR

NAO_ENCONTROU:
addi $v0, $zero, 0 # a(n) = 0

SALVAR:
 # salvar seq[n] = v0
    lui  $t5, 0x1001 # carrega a parte alta
    ori  $t5, $t5, 0x0028 # completa com a parte baixa
    sll  $t6, $a0, 2 # multiplica n ($a0) por 4 para obter o deslocamento em bytes
    add  $t7, $t5, $t6  
    sw   $v0, 0($t7) # coloca na memoria o $v0 na posicao seq[n]
    
    # Restaura $ra e $s0-$s7
    lw $ra, 0($sp) 
    lw $s0, 8($sp)
    lw $s1, 12($sp)
    lw $s2, 16($sp)
    lw $s3, 20($sp)
    lw $s4, 24($sp)
    lw $s5, 28($sp)
    lw $s6, 32($sp)
    lw $s7, 36($sp)

    # Libera o espaco da pilha (40 bytes)
    addi $sp, $sp, 40

    jr   $ra  # retorna com v0 = a(n)


PROC_FIBONACCI:
	# Caso base
	# if (n < 2)
	#	return 1
	slti $t0, $a0, 3			# a0 < 3?
	beq $t0, $zero, PROC_FIBONACCI_FIM_IF	# Se a0 for maior ou igual a 2, pula para o fim do if
		addi $v0, $zero, 1		# Retorna 1
		jr $ra				# Retorna para a recursao anterior
	PROC_FIBONACCI_FIM_IF:
	
	addi $fp, $sp, 0	# Guarda o inicio da pilha
	addi $sp, $sp, -20	# Aloca o espaco na pilha
	
	# Guardar informacoes
	# $a0
	# $s0
	# $s1
	# $ra
	# $fp
	sw $a0, 0($fp)		# Armazena $a0
	sw $s0, -4($fp)		# Armazena $s0
	sw $s1, -8($fp)		# Armazena $s1
	sw $ra, -12($fp)	# Armazena $ra	
	sw $fp, -16($fp)	# Armazena $fp
	
	# Primeira chamada recursiva
	addi $a0, $a0, -1	# Decrementa $a0 em 1
	jal PROC_FIBONACCI	# Faz a chamada recursiva
	addi $s0, $v0, 0	# Recebe o retorno da chamada
	
	# Segunda chamada recurvisa
	addi $a0, $a0, -1	# Decrementa $a0 em 1 unidade
	jal PROC_FIBONACCI	# Faz a chamada recursiva
	addi $s1, $v0, 0		# Recebe o retorno da chamada
	
	# Recupera os valores da pilha
	lw $fp, 4($sp)		# Recupera o inicio da pilha
	lw $a0, 0($fp)		# Recupera $a0
	lw $ra, -12($fp)		# Recupera $ra
	
	# Retorno
	add $t0, $s0, $s1	# fibo1 + fibo2
	addi $v0, $t0, 0	# Passa para o retorno o resultado
	
	# Recupera $s0 e $s1
	lw $s0, -4($fp)	# Recupera $s0
	lw $s1, -8($fp)	# Recupera $s1
	
	addi $sp, $fp, 0	# Recupera a pilha
	jr $ra			# Retorna para as chamadas
FIM_PROC_FIBONACCI:


#==========================================================================
# FUNCO DE MEDIA
#==========================================================================
# Argumentos:
#   $s0 - (Global) Ponteiro para o Acumulador
# Retorno:
#   $f0 - Media (float)
#==========================================================================
CALCULA_MEDIA:
    	# --- Guardar Registradores que serao usados ---
    	addi $sp, $sp, -16
    	sw    $ra, 0($sp)      # Salva endereco de retorno
    	sw    $s1, 4($sp)       # Salva $s1 (N)
    	sw    $s2, 8($sp)       # Salva $s2 (contador i)
    	swc1  $f1, 12($sp)       # Salva $f1 (Soma)

    	# --- Inicializacao ---
    	lw    $s1, 0($s0)       # $s1 = N (contador de valores)
    	addu  $s2, $zero, $zero # $s2 = i = 0
	mtc1  $zero, $f1        # $f1 = Soma = 0.0
	cvt.s.w $f1, $f1

	CALC_MEDIA_LOOP:
		# --- Condicao de Loop: if (i >= N) sai ---
		slt   $t2, $s2, $s1     # $t2 = 1 se (i < N)
		beq   $t2, $zero, CALC_MEDIA_LOOP_END

		# --- Corpo do Loop ---
		# Calcular endereco do valor: &acumulador[i+1]
		addi $t3, $s2, 1       # $t3 = i + 1
		ori   $t4, $zero, 4     # $t4 = 4 (bytes)
		mult  $t3, $t4
		mflo  $t3               # $t3 = (i+1) * 4
		addu  $t3, $s0, $t3     # $t3 = Endereco Base + Offset

		# Carregar a nota
    		lwc1  $f2, 0($t3)       # $f2 = nota[i]
    
    		# Acumular soma
    		add.s $f1, $f1, $f2     # Soma = Soma + nota[i]

    		# --- Incremento ---
    		addiu $s2, $s2, 1       # i++
    		beq   $zero, $zero, CALC_MEDIA_LOOP
	CALC_MEDIA_LOOP_END:
    
    	# --- Divisao ---
    	# Converter N (inteiro em $s1) para N (float em $f2)
    	mtc1  $s1, $f2
    	cvt.s.w $f2, $f2
    
    	# $f0 = Soma / N
    	div.s $f0, $f1, $f2     # $f0 o registrador de retorno

	# --- Recuperar Dados ---
	lw    $ra, 0($sp)
	lw    $s1, 4($sp)
	lw    $s2, 8($sp)
        lwc1  $f1, 12($sp)
        addi $sp, $sp, 16

    	jr $ra	# Retorna para o chamador

FIM_CALCULA_MEDIA:

#==========================================================================
# FUNCAO DE DESVIO PADRAO (AMOSTRAL, N-1)
#==========================================================================
# Argumentos:
#   $s0 - (Global) Ponteiro para o Acumulador
# Retorno:
#   $f0 - Desvio Padrao (float)
#==========================================================================
CALCULA_DESVIO_PADRAO:
    	# --- Guardar Registradores que serao usados ---
    	addiu $sp, $sp, -40
    	sw    $ra, 36($sp)      # Salva retorno
    	swc1  $f20, 20($sp)     # Salva $f20 (Media)
    	swc1  $f25, 0($sp)      # Salva $f25 (Soma dos Quadrados)
    	sw    $s1, 32($sp)      # Salva $s1 (N)
    	sw    $s2, 28($sp)      # Salva $s2 (contador i)
    	# (Nao precisamos salvar $f21-f24 pois agora lemos em loop)

    	# --- Carregar N ---
    	lw    $s1, 0($s0)       # $s1 = N (contador)

	# --- Passo 1: Chamar 'CALCULA_MEDIA' ---
    	# A funcao CALCULA_MEDIA usa $s0 (global)
    	jal   CALCULA_MEDIA
    	# A media retorna em $f0
    	mov.s $f20, $f0         # Salva a media em $f20

    	# --- Passo 2: Calcular a soma dos quadrados das diferencas: Î£(xi - Î¼)Â² ---
    	addu  $s2, $zero, $zero # i = 0
    	mtc1  $zero, $f25       # SomaQuadrados = 0.0

	DESVIO_LOOP:
    	# --- Condicao de Loop: if (i >= N) sai ---
    	slt   $t2, $s2, $s1     # $t2 = 1 se (i < N)
    	beq   $t2, $zero, DESVIO_LOOP_END
    
    	# --- Corpo do Loop ---
    	# Calcular endereco da nota: &acumulador[i+1]
    	addiu $t3, $s2, 1       # $t3 = i + 1
    	ori   $t4, $zero, 4     # $t4 = 4 (bytes)
   	mult  $t3, $t4
    	mflo  $t3               # $t3 = (i+1) * 4
    	addu  $t3, $s0, $t3     # $t3 = Endereco Base + Offset

    	# Carregar a nota
    	lwc1  $f1, 0($t3)       # $f1 = nota[i]

    	# Calcular (nota[i] - Î¼)
    	sub.s $f2, $f1, $f20    # $f2 = nota[i] - Î¼
    
    	# Calcular (nota[i] - Î¼)Â²
    	mul.s $f2, $f2, $f2     # $f2 = (nota[i] - Î¼)Â²
    
    	# Acumular soma
    	add.s $f25, $f25, $f2   # SomaQuadrados += (nota[i] - Î¼)Â²

    	# --- Incremento ---
    	addiu $s2, $s2, 1       # i++
    	beq   $zero, $zero, DESVIO_LOOP
	DESVIO_LOOP_END:
    
    	# $f25 agora contem a Soma dos Quadrados
    
    	# --- Passo 3: Calcular a Variancia Amostral (Soma / (N-1)) ---
    
    	# Calcular N-1
    	addiu $t0, $s1, -1      # $t0 = N - 1
    
	mtc1  $t0, $f1          # Move (N-1) para o coprocessador
	cvt.s.w $f1, $f1        # Converte (N-1) para float
    
    	# $f25 = SomaQuadrados / (N-1)
    	div.s $f25, $f25, $f1   # $f25 = Variancia Amostral
    
    	# --- Passo 4: Calcular o Desvio Padrao (Raiz da Variancia) ---
    	sqrt.s $f0, $f25        # $f0 = Desvio Padrao (retorno)

    	# --- EpÃ­logo ---
    	lw    $s2, 28($sp)
    	lw    $s1, 32($sp)
    	lwc1  $f25, 0($sp)
    	lwc1  $f20, 20($sp)
    	lw    $ra, 36($sp)
    	addiu $sp, $sp, 40

    	jr $ra
FIM_CALCULA_DESVIO_PADRAO:


#=========================
# Rotina para limpar tudo
#=========================
CLEAR_ALL:
	# Guardar registradores
	addi $sp, $sp, -4
	sw $ra, 4($sp)

	jal CLEAR_DISPLAY
	
	jal CLEAR_ACCUMULATOR

	# Recuperar registradores
	lw $ra, 4($sp)
	addi $sp, $sp, 4

	jr $ra

END_CLEAR_ALL:
