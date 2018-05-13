# Versión incompleta del tetris 
# Sincronizada con tetris.s:r2916
        
	.data	
cadena_puntos:
	.space 256
	
puntuacion_actual:
	.word 0

pantalla:
	.word	0
	.word	0
	.space	1024

campo:
	.word	0
	.word	0
	.space	1024

pieza_actual:
	.word	0
	.word	0
	.space	1024

pieza_actual_x:
	.word 0

pieza_actual_y:
	.word 0

imagen_auxiliar:
	.word	0
	.word	0
	.space	1024

pieza_jota:
	.word	2
	.word	3
	.ascii		"\0#\0###\0\0"

pieza_ele:
	.word	2
	.word	3
	.ascii		"#\0#\0##\0\0"

pieza_barra:
	.word	1
	.word	4
	.ascii		"####\0\0\0\0"

pieza_zeta:
	.word	3
	.word	2
	.ascii		"##\0\0##\0\0"

pieza_ese:
	.word	3
	.word	2
	.ascii		"\0####\0\0\0"

pieza_cuadro:
	.word	2
	.word	2
	.ascii		"####\0\0\0\0"

pieza_te:
	.word	3
	.word	2
	.ascii		"\0#\0###\0\0"

piezas:
	.word	pieza_jota
	.word	pieza_ele
	.word	pieza_zeta
	.word	pieza_ese
	.word	pieza_barra
	.word	pieza_cuadro
	.word	pieza_te

acabar_partida:
	.byte	0

	.align	2
procesar_entrada.opciones:
	.byte	'x'
	.space	3
	.word	tecla_salir
	.byte	'j'
	.space	3
	.word	tecla_izquierda
	.byte	'l'
	.space	3
	.word	tecla_derecha
	.byte	'k'
	.space	3
	.word	tecla_abajo
	.byte	'i'
	.space	3
	.word	tecla_rotar


str000:
	.asciiz		"Tetris\n\n 1 - Jugar\n 2 - Salir\n\nElige una opción:\n"
str001:
	.asciiz		"\n¡Adiós!\n"
str002:
	.asciiz		"\nOpción incorrecta. Pulse cualquier tecla para seguir.\n"
str003:
	.asciiz		"Puntuacion: \n"


	.text	

imagen_pixel_addr:			# ($a0, $a1, $a2) = (imagen, x, y)
					# pixel_addr = &data + y*ancho + x
    	lw	$t1, 0($a0)		# $a0 = dirección de la imagen 
					# $t1 ← ancho
    	mul	$t1, $t1, $a2		# $a2 * ancho
    	addu	$t1, $t1, $a1		# $a2 * ancho + $a1
    	addiu	$a0, $a0, 8		# $a0 ← dirección del array data
    	addu	$v0, $a0, $t1		# $v0 = $a0 + $a2 * ancho + $a1
    	jr	$ra

imagen_get_pixel:			# ($a0, $a1, $a2) = (img, x, y)
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)		# guardamos $ra porque haremos un jal
	jal	imagen_pixel_addr	# (img, x, y) ya en ($a0, $a1, $a2)
	lb	$v0, 0($v0)		# lee el pixel a devolver
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

imagen_set_pixel:
	addiu	$sp, $sp, -8
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	move	$s0, $a3	
	jal	imagen_pixel_addr	# (img, x, y) ya en ($a0, $a1, $a2)
	sb	$s0, 0($v0)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 8
	jr	$ra
	

imagen_clean:				
	addiu	$sp, $sp, -28
	sw	$ra, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)
	lw	$s1, 0($a0)		#ancho, fin contador
	lw	$s0, 4($a0)		#alto, fin contador
	add	$s3, $zero, $zero	#alto actual
	move	$s4, $a0		#primer parametro de entrada
	move	$s5, $a1		#segundo parametro de entrada
	#  for (int y = 0; y < img->alto; ++y)
buclealto:	
	bgeu	$s3, $s0, finalto
	add	$s2, $zero, $zero	#ancho actual
	#  for (int x = 0; x < img->ancho; ++x)
bucleancho:
	bgeu	$s2, $s1, financho
	move	$a0, $s4
	move	$a1, $s2
	move	$a2, $s3
	move	$a3, $s5
	jal	imagen_set_pixel
	addi	$s2, $s2, 1
	j	bucleancho
financho:
	addi	$s3, $s3, 1
	j	buclealto
finalto:
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$s4, 16($sp)
	lw	$s5, 20($sp)
	lw	$ra, 24($sp)
	addiu	$sp, $sp, 28
	jr	$ra		

        
imagen_init:	
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	sw	$a1, 0($a0)
	sw	$a2, 4($a0)
	move	$a1, $a3
	jal	imagen_clean
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra

imagen_copy:				#ojo, recorres las columnas de cada fila
	addiu	$sp, $sp, -28
	sw	$ra, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)
	move	$s4, $a0
	move	$s5, $a1
	lw	$s2, 0($s5)		#fin contador ancho en s2
	sw	$s2, 0($s4)
	lw	$s3, 4($s5)		#fin contador alto en s3
	sw	$s3, 4($s4)
	add	$s0, $zero, $zero	#contador alto s0
buclealto1:
	bgeu	$s0, $s3, finalto1
	add	$s1, $zero, $zero	#contador ancho s1
bucleancho1:
	bgeu	$s1, $s2, financho1 
	move	$a0, $s5
	move	$a1, $s1
	move	$a2, $s0
	jal	imagen_get_pixel
	move	$a3, $v0
	move	$a0, $s4
	move	$a1, $s1
	move	$a2, $s0
	jal	imagen_set_pixel
	addi	$s1, $s1, 1
	j	bucleancho1
financho1:
	addi	$s0, $s0, 1
	j 	buclealto1
finalto1:
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$s4, 16($sp)
	lw	$s5, 20($sp)
	lw	$ra, 24($sp)
	addiu	$sp, $sp, 28
	jr	$ra

imagen_print:				# $a0 = img
	addiu	$sp, $sp, -24
	sw	$ra, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)
	move	$s0, $a0
	lw	$s3, 4($s0)		# img->alto
	lw	$s4, 0($s0)		# img->ancho
        #  for (int y = 0; y < img->alto; ++y)
	li	$s1, 0			# y = 0
B6_2:	bgeu	$s1, $s3, B6_5		# acaba si y ≥ img->alto
	#    for (int x = 0; x < img->ancho; ++x)
	li	$s2, 0			# x = 0
B6_3:	bgeu	$s2, $s4, B6_4		# acaba si x ≥ img->ancho
	move	$a0, $s0		# Pixel p = imagen_get_pixel(img, x, y)
	move	$a1, $s2
	move	$a2, $s1
	jal	imagen_get_pixel
	move	$a0, $v0		# print_character(p)
	jal	print_character
	addiu	$s2, $s2, 1		# ++x
	j	B6_3
	#    } // for x
B6_4:	li	$a0, 10			# print_character('\n')
	jal	print_character
	addiu	$s1, $s1, 1		# ++y
	j	B6_2
	#  } // for y
B6_5:	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$s4, 16($sp)
	lw	$ra, 20($sp)
	addiu	$sp, $sp, 24
	jr	$ra
	

imagen_dibuja_imagen:
	addiu	$sp, $sp, -36
	sw	$ra, 32($sp)
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)
	move	$s6, $a2		#s6 tenemos dstx
	move	$s7, $a3		#s7 tenemos dsty
	move	$s5, $a1
	move	$s4, $a0
	lw	$s2, 0($a1)		#fin contador ancho en s2
	lw	$s3, 4($a1)		#fin contador alto en s3
	add	$s0, $zero, $zero	#contador alto s0
buclealto2:
	bgeu	$s0, $s3, finalto2
	add	$s1, $zero, $zero	#contador ancho s1
bucleancho2:
	bgeu	$s1, $s2, financho2
	move	$a0, $s5
	move	$a1, $s1
	move	$a2, $s0
	jal 	imagen_get_pixel
	beqz	$v0, pixelvacio
	move 	$a0, $s4
	add	$a1, $s6, $s1
	add	$a2, $s7, $s0
	move	$a3, $v0
	jal	imagen_set_pixel
		
pixelvacio:
	addi	$s1, $s1, 1
	j	bucleancho2
financho2:
	addi	$s0, $s0, 1
	j 	buclealto2
finalto2:	
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$s4, 16($sp)
	lw	$s5, 20($sp)
	lw	$s6, 24($sp)
	lw	$s7, 28($sp)
	lw	$ra, 32($sp)
	addiu	$sp, $sp, 36
	jr	$ra

imagen_dibuja_imagen_rotada:
	addiu	$sp, $sp, -36
	sw	$ra, 32($sp)
	sw	$s7, 28($sp)
	sw	$s6, 24($sp)
	sw	$s5, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)
	
	lw	$s0, 0($a1)
	lw	$s1, 4($a1)
	move	$s4, $a1
	move	$s5, $a0
	move	$s6, $a2
	move	$s7, $a3
	li	$s2, 0
alto3:	bge	$s2, $s1, fin_alto3
	li	$s3, 0
ancho3: bge	$s3, $s0, fin_ancho3
	move	$a0, $s4
	move	$a1, $s3
	move	$a2, $s2
	jal	imagen_get_pixel
	beqz	$v0, comp1
	move	$a0, $s5
	sub	$a1, $s6, $s2
	add	$a1, $a1, $s1
	subiu	$a1, $a1, 1
	add	$a2, $s7, $s3
	move	$a3, $v0
	jal	imagen_set_pixel
comp1:	addiu	$s3, $s3, 1
	j	ancho3
fin_ancho3: 
	addiu 	$s2, $s2, 1
	j 	alto3
fin_alto3:
	
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$s4, 16($sp)
	lw	$s5, 20($sp)
	lw	$s6, 24($sp)
	lw	$s7, 28($sp)
	lw	$ra, 32($sp)
	addiu	$sp, $sp, 36
	jr	$ra
pieza_aleatoria:
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	li	$a0, 0
	li	$a1, 7
	jal	random_int_range	# $v0 ← random_int_range(0, 7)
	sll	$t1, $v0, 2
	la	$v0, piezas
	addu	$t1, $v0, $t1		# $t1 = piezas + $v0*4
	lw	$v0, 0($t1)		# $v0 ← piezas[$v0]
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

actualizar_pantalla:
	addiu	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$s2, 4($sp)
	sw	$s1, 0($sp)
	la	$s2, campo
	la	$a0, pantalla
	li	$a1, ' '
	jal	imagen_clean		# imagen_clean(pantalla, ' ')
        # for (int y = 0; y < campo->alto; ++y) {
	li	$s1, 0			# y = 0
B10_2:	lw	$t1, 4($s2)		# campo->alto
	bge	$s1, $t1, B10_3		# sigue si y < campo->alto
	la	$a0, pantalla
	li	$a1, 0                  # pos_campo_x - 1
	addi	$a2, $s1, 2             # y + pos_campo_y
	li	$a3, '|'
	jal	imagen_set_pixel	# imagen_set_pixel(pantalla, 0, y, '|')
	la	$a0, pantalla
	lw	$t1, 0($s2)		# campo->ancho
	addiu	$a1, $t1, 1		# campo->ancho + 1
	addiu	$a2, $s1, 2             # y + pos_campo_y
	li	$a3, '|'
	jal	imagen_set_pixel	# imagen_set_pixel(pantalla, campo->ancho + 1, y, '|')
        addiu	$s1, $s1, 1		# ++y
        j       B10_2
        # } // for y
	# for (int x = 0; x < campo->ancho + 2; ++x) { 
B10_3:	li	$s1, 0			# x = 0
B10_5:  lw	$t1, 0($s2)		# campo->ancho
        addiu   $t1, $t1, 2             # campo->ancho + 2
        bge	$s1, $t1, B10_6		# sigue si x < campo->ancho + 2
	la	$a0, pantalla
	move	$a1, $s1                # pos_campo_x - 1 + x
        lw	$t1, 4($s2)		# campo->alto
	addiu	$a2, $t1, 2		# campo->alto + pos_campo_y
	li	$a3, '-'
	jal	imagen_set_pixel	# imagen_set_pixel(pantalla, x, campo->alto + 1, '-')
	addiu	$s1, $s1, 1		# ++x
	j       B10_5
        # } // for x
B10_6:	la	$a0, pantalla
	move	$a1, $s2
	li	$a2, 1                  # pos_campo_x
	li	$a3, 2                  # pos_campo_y
	jal	imagen_dibuja_imagen	# imagen_dibuja_imagen(pantalla, campo, 1, 2)
	la	$a0, pantalla
	la	$a1, pieza_actual
	lw	$t1, pieza_actual_x
	addiu	$a2, $t1, 1		# pieza_actual_x + pos_campo_x
	lw	$t1, pieza_actual_y
	addiu	$a3, $t1, 2		# pieza_actual_y + pos_campo_y
	jal	imagen_dibuja_imagen	# imagen_dibuja_imagen(pantalla, pieza_actual, pieza_actual_x + pos_campo_x, pieza_actual_y + pos_campo_y)
	
	jal	clear_screen		# clear_screen()
	
	la 	$a0, pantalla		# Imagen
	la	$a1, str003		# 'Puntuacion :'
	li	$a2, 0			# Coordenada x
	li	$a3, 0			# Coordenada y
	jal 	imagen_dibuja_cadena
	
	lw 	$a0, puntuacion_actual	# Cargamos la punt. actual
	li	$a1, 10			# Carga la base 10
	la	$a2, cadena_puntos	# Buff donde meteremos el entero
	jal 	integer_to_string_v4
	
	la 	$a0, pantalla		# Imagen
	la	$a1, cadena_puntos	# 'Puntuacion :'
	li	$a2, 12			# Coordenada x
	li	$a3, 0			# Coordenada y
	jal 	imagen_dibuja_cadena
	
	
	la	$a0, pantalla
	jal	imagen_print		# imagen_print(pantalla)
	
	lw	$s1, 0($sp)
	lw	$s2, 4($sp)
	lw	$ra, 8($sp)
	addiu	$sp, $sp, 12
	jr	$ra

nueva_pieza_actual:
	addi	$sp,$sp,-4
	sw	$ra, 0($sp)
	jal	pieza_aleatoria
	move	$a1, $v0
	la	$a0, pieza_actual
	jal	imagen_copy
	la	$t0, pieza_actual_x
	li	$t1, 8
	sw	$t1, 0($t0)
	la	$t0, pieza_actual_y
	li	$t1, 0
	sw	$t1, 0($t0)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
	

probar_pieza:				# ($a0, $a1, $a2) = (pieza, x, y)
	addiu	$sp, $sp, -32
	sw	$ra, 28($sp)
	sw	$s7, 24($sp)
	sw	$s6, 20($sp)
	sw	$s4, 16($sp)
	sw	$s3, 12($sp)
	sw	$s2, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)
	move	$s0, $a2		# y
	move	$s1, $a1		# x
	move	$s2, $a0		# pieza
	li	$v0, 0
	bltz	$s1, B12_13		# if (x < 0) return false
	lw	$t1, 0($s2)		# pieza->ancho
	addu	$t1, $s1, $t1		# x + pieza->ancho
	la	$s4, campo
	lw	$v1, 0($s4)		# campo->ancho
	bltu	$v1, $t1, B12_13	# if (x + pieza->ancho > campo->ancho) return false
	bltz	$s0, B12_13		# if (y < 0) return false
	lw	$t1, 4($s2)		# pieza->alto
	addu	$t1, $s0, $t1		# y + pieza->alto
	lw	$v1, 4($s4)		# campo->alto
	bltu	$v1, $t1, B12_13	# if (campo->alto < y + pieza->alto) return false
	# for (int i = 0; i < pieza->ancho; ++i) {
	lw	$t1, 0($s2)		# pieza->ancho
	beqz	$t1, B12_12
	li	$s3, 0			# i = 0
	#   for (int j = 0; j < pieza->alto; ++j) {
	lw	$s7, 4($s2)		# pieza->alto
B12_6:	beqz	$s7, B12_11
	li	$s6, 0			# j = 0
B12_8:	move	$a0, $s2
	move	$a1, $s3
	move	$a2, $s6
	jal	imagen_get_pixel	# imagen_get_pixel(pieza, i, j)
	beqz	$v0, B12_10		# if (imagen_get_pixel(pieza, i, j) == PIXEL_VACIO) sigue
	move	$a0, $s4
	addu	$a1, $s1, $s3		# x + i
	addu	$a2, $s0, $s6		# y + j
	jal	imagen_get_pixel
	move	$t1, $v0		# imagen_get_pixel(campo, x + i, y + j)
	li	$v0, 0
	bnez	$t1, B12_13		# if (imagen_get_pixel(campo, x + i, y + j) != PIXEL_VACIO) return false
B12_10:	addiu	$s6, $s6, 1		# ++j
	bltu	$s6, $s7, B12_8		# sigue si j < pieza->alto
        #   } // for j
B12_11:	lw	$t1, 0($s2)		# pieza->ancho
	addiu	$s3, $s3, 1		# ++i
	bltu	$s3, $t1, B12_6 	# sigue si i < pieza->ancho
        # } // for i
B12_12:	li	$v0, 1			# return true
B12_13:	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s2, 8($sp)
	lw	$s3, 12($sp)
	lw	$s4, 16($sp)
	lw	$s6, 20($sp)
	lw	$s7, 24($sp)
	lw	$ra, 28($sp)
	addiu	$sp, $sp, 32
	jr	$ra

intentar_movimiento:
	addiu	$sp, $sp, -12
	sw	$s0, 0($sp)
	sw	$s1, 4($sp)
	sw	$ra, 8($sp)
	move	$s0, $a0
	move	$s1, $a1
	move	$a2, $a1
	move	$a1, $a0
	la	$a0, pieza_actual
	jal	probar_pieza
	beqz 	$v0, falsisimo
	sw	$s0, pieza_actual_x
	sw	$s1, pieza_actual_y
falsisimo:
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$ra, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra

bajar_pieza_actual:
	addiu	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	
	la	$s0, pieza_actual_x
	la	$s1, pieza_actual_y
	lw	$a0, 0($s0)
	lw	$a1, 0($s1)
	addiu	$a1, $a1, 1
	jal 	intentar_movimiento
	bnez	$v0, falsisimo2
	la	$a0, campo
	la	$a1, pieza_actual
	lw	$a2, 0($s0)
	lw	$a3, 0($s1)
	jal	imagen_dibuja_imagen
	jal	nueva_pieza_actual
		
	
	lw	$t9, puntuacion_actual
	addi	$t9, $t9, 1
	sw	$t9, puntuacion_actual
	


falsisimo2:
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 12
	jr	$ra

intentar_rotar_pieza_actual:
	addi	$sp, $sp, -8
	sw	$s0, 0($sp)
	sw	$ra, 4($sp)
	la	$s0, imagen_auxiliar
	la	$t0, pieza_actual
	move	$a0, $s0
	lw	$a1, 4($t0)
	lw	$a2, 0($t0)
	move	$a3, $zero
	jal	imagen_init
	move	$a0, $s0
	la	$a1, pieza_actual
	move	$a2, $zero
	move	$a3, $zero
	jal	imagen_dibuja_imagen_rotada
	move	$a0, $s0
	la	$a1, pieza_actual_x
	lw	$a1, 0($a1)
	la	$a2, pieza_actual_y
	lw	$a2, 0($a2)
	jal	probar_pieza
	beqz	$v0, finiquitao_otravez
	la	$a0, pieza_actual
	move	$a1, $s0
	jal	imagen_copy
finiquitao_otravez:
	lw	$s0, 0($sp)
	lw	$ra, 4($sp)
	addi	$sp,$sp, 8
	jr	$ra
	
	

tecla_salir:
	li	$v0, 1
	sb	$v0, acabar_partida	# acabar_partida = true
	jr	$ra

tecla_izquierda:
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	lw	$a1, pieza_actual_y
	lw	$t1, pieza_actual_x
	addiu	$a0, $t1, -1
	jal	intentar_movimiento	# intentar_movimiento(pieza_actual_x - 1, pieza_actual_y)
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

tecla_derecha:
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	lw	$a1, pieza_actual_y
	lw	$t1, pieza_actual_x
	addiu	$a0, $t1, 1
	jal	intentar_movimiento	# intentar_movimiento(pieza_actual_x + 1, pieza_actual_y)
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

tecla_abajo:
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	bajar_pieza_actual	# bajar_pieza_actual()
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

tecla_rotar:
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	jal	intentar_rotar_pieza_actual	# intentar_rotar_pieza_actual()
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

procesar_entrada:
	addiu	$sp, $sp, -20
	sw	$ra, 16($sp)
	sw	$s4, 12($sp)
	sw	$s3, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)
	jal	keyio_poll_key
	move	$s0, $v0		# int c = keyio_poll_key()
        # for (int i = 0; i < sizeof(opciones) / sizeof(opciones[0]); ++i) { 
	li	$s1, 0			# i = 0, $s1 = i * sizeof(opciones[0]) // = i * 8
	la	$s3, procesar_entrada.opciones	
	li	$s4, 40			# sizeof(opciones) // == 5 * sizeof(opciones[0]) == 5 * 8
B21_1:	addu	$t1, $s3, $s1		# procesar_entrada.opciones + i*8
	lb	$t2, 0($t1)		# opciones[i].tecla
	bne	$t2, $s0, B21_3		# if (opciones[i].tecla != c) siguiente iteración
	lw	$t2, 4($t1)		# opciones[i].accion
	jalr	$t2			# opciones[i].accion()
	jal	actualizar_pantalla	# actualizar_pantalla()
B21_3:	addiu	$s1, $s1, 8		# ++i, $s1 += 8
	bne	$s1, $s4, B21_1		# sigue si i*8 < sizeof(opciones)
        # } // for i
	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$s3, 8($sp)
	lw	$s4, 12($sp)
	lw	$ra, 16($sp)
	addiu	$sp, $sp, 20
	jr	$ra

jugar_partida:
	addiu	$sp, $sp, -12	
	sw	$ra, 8($sp)
	sw	$s1, 4($sp)
	sw	$s0, 0($sp)
	la	$a0, pantalla
	li	$a1, 20
	li	$a2, 22
	li	$a3, 32
	jal	imagen_init		# imagen_init(pantalla, 20, 22, ' ')
	la	$a0, campo
	li	$a1, 14
	li	$a2, 18
	li	$a3, 0
	jal	imagen_init		# imagen_init(campo, 14, 18, PIXEL_VACIO)
	jal	nueva_pieza_actual	# nueva_pieza_actual()
	sb	$zero, acabar_partida	# acabar_partida = false
	jal	get_time		# get_time()
	move	$s0, $v0		# Hora antes = get_time()
	jal	actualizar_pantalla	# actualizar_pantalla()
	j	B22_2
        # while (!acabar_partida) { 
B22_2:	lbu	$t1, acabar_partida
	bnez	$t1, B22_5		# if (acabar_partida != 0) sale del bucle
	jal	procesar_entrada	# procesar_entrada()
	jal	get_time		# get_time()
	move	$s1, $v0		# Hora ahora = get_time()
	subu	$t1, $s1, $s0		# int transcurrido = ahora - antes
	ble	$t1, 1000, B22_2	# if (transcurrido < pausa) siguiente iteración
B22_1:	jal	bajar_pieza_actual	# bajar_pieza_actual()
	jal	actualizar_pantalla	# actualizar_pantalla()
	move	$s0, $s1		# antes = ahora
        j	B22_2			# siguiente iteración
       	# } 
B22_5:	lw	$s0, 0($sp)
	lw	$s1, 4($sp)
	lw	$ra, 8($sp)
	addiu	$sp, $sp, 12
	jr	$ra

	.globl	main
main:					# ($a0, $a1) = (argc, argv) 
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
B23_2:	jal	clear_screen		# clear_screen()
	la	$a0, str000
	jal	print_string		# print_string("Tetris\n\n 1 - Jugar\n 2 - Salir\n\nElige una opción:\n")
	jal	read_character		# char opc = read_character()
	beq	$v0, '2', B23_1		# if (opc == '2') salir
	bne	$v0, '1', B23_5		# if (opc != '1') mostrar error
	jal	jugar_partida		# jugar_partida()
	j	B23_2
B23_1:	la	$a0, str001
	jal	print_string		# print_string("\n¡Adiós!\n")
	li	$a0, 0
	jal	mips_exit		# mips_exit(0)
	j	B23_2
B23_5:	la	$a0, str002
	jal	print_string		# print_string("\nOpción incorrecta. Pulse cualquier tecla para seguir.\n")
	jal	read_character		# read_character()
	j	B23_2
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

#
# Funciones de la librería del sistema
#

print_character:
	li	$v0, 11
	syscall	
	jr	$ra

print_string:
	li	$v0, 4
	syscall	
	jr	$ra

get_time:
	li	$v0, 30
	syscall	
	move	$v0, $a0
	move	$v1, $a1
	jr	$ra

read_character:
	li	$v0, 12
	syscall	
	jr	$ra

clear_screen:
	li	$v0, 39
	syscall	
	jr	$ra

mips_exit:
	li	$v0, 17
	syscall	
	jr	$ra

random_int_range:
	li	$v0, 42
	syscall	
	move	$v0, $a0
	jr	$ra

keyio_poll_key:
	li	$v0, 0
	lb	$t0, 0xffff0000
	andi	$t0, $t0, 1
	beqz	$t0, keyio_poll_key_return
	lb	$v0, 0xffff0004
keyio_poll_key_return:
	jr	$ra









main2:                    # ($a0, $a1) = (argc, argv) 
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)

    # prueba de imagen_init, imagen_clean e imagen_set_pixel
    la    $a0, pantalla
    li    $a1, 10
    li    $a2, 8
    li    $a3, 'x'
    jal   imagen_init 
    la	  $a0, campo
    la    $a1, pantalla
    jal	  imagen_copy
           

    # prueba imagen_dibuja_imagen
    #la    $a0, pantalla
    #la    $a1, pieza_ese
    #li    $a2, 2
    #li    $a3, 3
    #jal   imagen_dibuja_imagen
            
    la     $a0, campo
    jal    imagen_print

    jal    mips_exit

    lw     $ra, 0($sp)
    addiu  $sp, $sp, 4
    jr     $ra
    
integer_to_string_v4:			# ($a0, $a1, $a2) = (n, base, buf)
	move    $t0, $a2		# char *p = buff
	
	bnez	$a0, B4_2		#Tratamiento completo si n=0
	addiu	$t1, $zero, '0'		#Obtenemos el caracter correspondiente a 0
	sb	$t1, 0($t0)		#Cargamos el 0 en memoria
	addiu	$t0, $t0, 1		#Avanzamos un byte (para marcar el fin de la cadena)
	sb	$zero ,0($t0)		#Marcamos el fin de la cadena (*p = '/0')
	j	B4_10			#Saltamos a la etiqueta que sale del procedimiento
	
	# for (int i = n; i > 0; i = i / base) {
B4_2:   move	$t1, $a0		# int i = n
    	abs	$t1, $t1		#Trabajamos con el valor absoluto de n
B4_3:   blez	$t1, B4_7		# si i <= 0 salta el bucle
	div	$t1, $a1		# i / base
	mflo	$t1			# i = i / base
	mfhi	$t2			# d = i % base
	
	bge	$t2, 10, B4_4		#Si el caracter a almacenar es mayor que 10 se le debe sumar 55
	addiu	$t2, $t2, '0'		# d + '0'
	j	B4_5			#Salta a etiqueta para cargar el byte en memoria y seguir con el bucle
	
B4_4:	addiu	$t2, $t2, 55		#Para bases superiores sumamos el caracter A (codigo 65) menos 10
	
B4_5:	sb	$t2, 0($t0)		# *p = $t2 
	addiu	$t0, $t0, 1		# ++p (Se suma 1 pq cada elemento ocupa un byte)
	j	B4_3			# sigue el bucle
        # }
        

B4_7:	sb	$zero, 0($t0)		# *p = '\0'

	subiu	$t0,$t0,1		#No queremos tratar el final de cadena
B4_8:	bge   	$a2,$t0, B4_10		#Bucle para darle la vuelta a la cadena; la condición de parada es que $a2 y $t0
					#"se encuentren" porque damos la vuelta a la cadena utilizando la cabeza y la cola de esta
	lb	$t3, 0($a2)		#Cargamos la dirección de memoria a un registro $t3 para no macharla
	lb	$t4, 0($t0)		#Cargamos la dirección de memoria a un registro $t4 para no macharla
	sb	$t4,0($a2)		#Intercambiamos las variables almacenándolas en memoria
	sb 	$t3,0($t0)		#Intercambiamos las variables almacenándolas en memoria
	addiu	$a2,$a2,1		#Incrementamos $a2
	subiu	$t0,$t0,1		#Decrementamos $t0
	j	B4_8			#Salto incondicional del bucle de intercambio
	
B4_10:	jr	$ra

imagen_dibuja_cadena:		#($a0,$a1, $a2,$a3) = (pantalla, dircadena, pos x, pos y)
	addiu	$sp, $sp, -24
	sw	$s0, 20($sp)
	sw	$s1, 16($sp)
	sw	$s2, 12($sp)
	sw	$s3, 8($sp)
	sw	$s4, 4($sp)
	sw	$ra, 0($sp)
	
	move	$s0, $a0	#$s0= pantalla
	move	$s1, $a1	#$s1= cadena
	move	$s2, $a2	#$s2=x
	move 	$s3, $a3	#$s3=y
	
setpixel:
	lb	$s4, 0($s1)	#Cargamos el caracter de la dirección $s1 en $s4
	beqz	$s4, finale	#Si el caracter es la marca de fin, saltamos fuera del bucle
	move	$a0, $s0	#$a0=pantalla
	move	$a1, $s2	#$a1=x
	move	$a2, $s3	#$a2=y
	move	$a3, $s4	#$a3=Pixel (el caracter)
	jal	imagen_set_pixel
	
	addi	$s1, $s1, 1	#Siguiente pixel
	addi	$s2, $s2, 1	#x++
	j	setpixel
finale:
	lw	$s0, 20($sp) 
	lw	$s1, 16($sp)
	lw	$s2, 12($sp)
	lw	$s3, 8($sp)
	lw	$s4, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 24
	jr	$ra
