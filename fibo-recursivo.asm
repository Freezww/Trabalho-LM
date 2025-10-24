# Implementar a sequencia de fibonacci recursiva

# n1 = fibonacci(n-1)
# n2 = fibonacci(n-2)

MAIN:
	# ler n -> $s0
	addi $v0, $zero, 5	# syscall para leitura de um inteiro
	syscall
	addi $s0, $v0, 0	# Recebe o retorno da leitura

	# fibo = fibonacci(n) -> $s1
	addi $a0, $s0, 0	# Passa o parametro para o procedimento
	jal PROC_FIBONACCI	# Salta para o proc fibonacci
	addi $s1, $v0, 0	# Recebe o retorno do proc fibonacci

	#imprimir fibo
	addi $v0, $zero, 1	# syscall para imprimir um inteiro
	addi $a0, $s1, 0	# Valor a ser impresso
	syscall
	
	#return 0
	addi $v0, $zero, 10	# syscall para encerramento do programa
	syscall
FIM_MAIN:


PROC_FIBONACCI:
	# Caso base
	# if (n < 2)
	#	return 1
	slti $t0, $a0, 3			# a0 < 2?
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
	addi $s1, $v0, 0	# Recebe o retorno da chamada
	
	# Recupera os valores da pilha
	lw $fp, 4($sp)		# Recupera o inicio da pilha
	lw $a0, 0($fp)		# Recupera $a0
	lw $ra, -12($fp)	# Recupera $ra
	
	# Retorno
	add $t0, $s0, $s1	# fibo1 + fibo2
	addi $v0, $t0, 0	# Passa para o retorno o resultado
	
	# Recupera $s0 e $s1
	lw $s0, -4($fp)	# Recupera $s0
	lw $s1, -8($fp)	# Recupera $s1
	
	addi $sp, $fp, 0	# Recupera a pilha
	jr $ra			# Retorna para as chamadas
FIM_PROC_FIBONACCI:





