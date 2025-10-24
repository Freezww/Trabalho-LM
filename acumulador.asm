.data
	# Endereço: 0x10010000
	MSG_FULL: .asciiz "Acumulador Cheio"	# 16 caracteres + '\0' = 17 Bytes
	.align 3									# Corrigir alinhamento para multiplo de 4
.text

# Alocar acumulador (global)
addi $v0, $zero, 9	# syscall para alocacao de memoria
addi $a0, $zero, 44	# Alocar 44 bits
syscall
addi $s0, $v0, 0		# Guarda o endereço do espaço de memória alocado

# Como fica o acumulador na memoria
# $s0 -> 0 - Quantidade de posicoes utilizadas
# 1 - Elemento 1
# 2 - Elemento 2
# 3 - Elemento 3
# 4 - Elemento 4
# 5 - Elemento 5
# 6 - Elemento 6
# 7 - Elemento 7
# 8 - Elemento 8
# 9 - Elemento 9
# 10 - Elemento 10

MAIN:
	# Inicializar i -> $t0
	addi $s2, $zero, 0
	
	FOR:
		# for (int i = 0, i < 10, ++i)
		slti $t0, $s2, 3	# Se i < 10, entao 1, se nao, 0
		beq $t0, $zero, END_FOR	# Se i >= 10, vai para fora de 

		# Leia X - > $s0
		addi $v0, $zero, 5
		syscall
		addi $s1, $v0, 0
	
		# inserirAcumulador(int x)
		addi $a0, $s1, 0
		jal INSERT_ACCUMULATOR
		
		addi $s2, $s2, 1	# ++i
		j FOR
	END_FOR:
	
	jal CLEAR_ACCUMULATOR
	
	# Zerar i
	addi $s2, $zero, 0
	
	FOR2:
		# for (int i = 0, i < 10, ++i)
		slti $t0, $s2, 4	# Se i < 10, entao 1, se nao, 0
		beq $t0, $zero, END_FOR2	# Se i >= 10, vai para fora de 

		# Leia X - > $s0
		addi $v0, $zero, 5
		syscall
		addi $s1, $v0, 0
	
		# inserirAcumulador(int x)
		addi $a0, $s1, 0
		jal INSERT_ACCUMULATOR
		
		addi $s2, $s2, 1	# ++i
		j FOR2
	END_FOR2:
	
	# Return 0
	addi $v0, $zero, 10
	syscall
END_MAIN:

#===========================================================

INSERT_ACCUMULATOR:
	# void inserirAcumulador(int x)
	# if (acumulador[0] < 11) {
	lw $t0, 0($s0)	# Obtem a quantidade de posicoes ocupadas
	slti $t1, $t0, 10	# acumulador[0] < 11 (11menor que 11 para questoes de facilidade)
	beq $t1, $zero,  INSERT_ACCUMULATOR_ELSE
		# Calcular deslocamento para insercao
		addi $t1, $zero, 4	# Constante 4
		mul $t2, $t1, $t0	# quant_ocupada * 4 = deslocamento em bytes
		addi $t2, $t2, 4	# Corrige o deslocamento (+4 bytes da primeira posição que não é válida para inserção)
		add $t2, $t2, $s0	# Soma ao endereço base para obter o endereço correto
		
		# Insercao do valor
		sw $a0, 0($t2)	# Armazena o valor no deslocamento correto
		addi $t0, $t0, 1	# quant_ocupada++
		sw $t0, 0($s0)	# acumulador[0] = quant_ocupada
		
		# Pular o ELSE
		j INSERT_ACCUMULATOR_END_IF
	
	INSERT_ACCUMULATOR_ELSE:
		# Imprimir string de erro na insercao
		lui $a0, 0x1001			# Carrega para a parte alta da palavra
		ori $a0, $a0, 00000000	# Carrega para a parte baixa da palavra
		addi $v0, $zero, 4		# syscall para imprimir string
		syscall
		
		# Quebra de linha
		addi $v0, $zero, 11
		addi $a0, $zero, 32
		syscall
		
	INSERT_ACCUMULATOR_END_IF:
		# Voltar ao chamador
		jr $ra	# Retorna a rotina que chamou (não possui valor de retorno)
		
END_INSERT_ACCUMULATOR:

#===========================================================

CLEAR_ACCUMULATOR:
	# Zerar quant_ocupado
	sw $zero, 0($s0)	# acumulador[0] = 0
	
	# Retornar para o chamador
	jr $ra
	
END_CLEAR_ACCUMULATOR:

#===========================================================








