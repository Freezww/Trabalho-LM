# leia 4 notas em ponto flutuante (single-precision)
# imprima media
#             ^-- Calculo da media com um procedimento
#
# Pesquisar sobre ponto flutuante em MIPS para fazer
#
# Quais os registradores utilizados para passagem de argumento float?
#	Os registradores utilizados para passagem de parametros sao:
#		- $f12
#		- $f13
#		- $f14
#		- $f15

# Quais os registradores utilizados para retorno em float?
#	Os registradores utilizados para retorno o par $f0 (single-precision) $f1 (junto de $f1
#	para double-precision).

# Registradores salvos pelo chamador:
# 	Os registradores $f0 até $f19 sao considerados "Caller-saved", ou seja, salvos pelo
#	chamador antes da chamada e restaurados após retorno.

# Registradores salvos pelo chamado:
#	Os registradores $f20 até $f31 sao considerados "Callee-saved", ou seja, o responsavel
#	por salva-los e restaura-los apos o retorno.

# Mapeamento dos elementos:
# Primeira nota -> $f2
# Segunda nota -> $f3
# Terceira nota -> $f4
# Quarta nota -> $f5

# Main do programa (apenas para indicar aonde comeca)
MAIN:
#==========================================================================
# Ler primeira nota
addi $v0, $zero, 6	# syscall para leitura de ponto flutuante (single)
syscall
mov.s $f2, $f0		# Guarda em $f2 o valor da primeira nota

# Ler segunda nota
addi $v0, $zero, 6	# syscall para leitura de ponto flutuante (single)
syscall
mov.s $f3, $f0		# Guarda em $f3 o valor da segunda nota

# Ler terceira nota
addi $v0, $zero, 6	# syscall para leitura de ponto flutuante (single)
syscall
mov.s $f4, $f0		# Guarda em $f4 o valor da terceira nota

# Ler quarta nota
addi $v0, $zero, 6	# syscall para leitura de ponto flutuante (single)
syscall
mov.s $f5, $f0		# Guarda em $f5 o valor da quarta nota
#==========================================================================

# Passa para os registradores de parametros os valores
mov.s $f12, $f2		# $f12 contem n1
mov.s $f13, $f3		# $f13 contem n2
mov.s $f14, $f4		# $f14 contem n3
mov.s $f15, $f5		# $f15 contem n4

# Chamada da funcao
jal CALCULA_MEDIA	# Retorno vem em $f0

# Guardar na memoria o valor
swc1 $f0, 0($sp)
lwc1 $f0, 0($sp)

# Impressao do valor
mov.s $f12, $f0
addi $v0, $zero, 2
syscall

# Finalizacao do programa
addi $v0, $zero, 10
syscall

#==========================================================================
CALCULA_MEDIA:
	# Somar os valores e armazenar em $f0
	add.s $f0, $f12, $f13	# Soma a primeira e a segunda nota (soma = n1 + n2) 
	add.s $f0, $f0, $f14	# Soma a terceira nota (soma += n3)
	add.s $f0, $f0, $f15	# Soma a quarta nota (soma += n4)
	
	# Atribui a constante 4 ao registrador $f1
	addi $t0, $zero, 4	# Carrega a constante 4 para $t0
	mtc1  $t0, $f1          # Move o valor para o registrador de ponto flutuante $f2
	cvt.s.w $f1, $f1	# Converte a palavra em ponto flutuante (single)
	
	# Faz a divisao por 4
	div.s $f0, $f0, $f1	# Soma = soma / 4 (Ja no registrador de retorno)
	# Retorno da funcao
	jr $ra
FIM_CALCULA_MEDIA:
#==========================================================================
