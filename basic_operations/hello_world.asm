.text

.global main
main:
	li $v0, 33 #bu ses dosyalarini ac demek
	li $a0, 60 #a0ya do notasini ekledim
	li $a1, 1000 #a1 sureyi belirliyo milisec olarak
	li $a2, 0 #a2 enstruman belirtir, 0 piyano
	li $a3, 100 #a3 ses seviyesini belirtir
	
	syscall
	
	li $v0, 10 #Bitirmek icin
	syscall
	
	