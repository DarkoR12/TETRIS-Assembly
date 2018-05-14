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
    	.asciiz     "Puntuacion: \n"
end0:
    	.asciiz     "+--------------+"
end1:
    	.asciiz     "|  GAME  OVER  |"
end2:
    	.asciiz     "|              |"
end3:
    	.asciiz     "|  Pulsa  una  |"
end4:
    	.asciiz     "|  tecla!      |"
end5:
    	.asciiz     "+--------------+"   	    	


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
	lbu	$v0, 0($v0)		# lee el pixel a devolver
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr	$ra

imagen_set_pixel:	# ($a0, $a1, $a2, $a3) = (*img, x, y, color)
	#void imagen_set_pixel(Imagen *img, int x, int y, Pixel color) {
  	#Pixel *pixel = imagen_pixel_addr(*img, x, y);
  	#*pixel = color;
	#}
	addiu	$sp, $sp, -8
	sw 	$ra, 4($sp)		# guardamos $ra porque haremos un jal
	sw	$s0, 0($sp)		# guardamos $s0 para utilizarlo luego
	
	move 	$s0, $a3 		# guardamos $a3 en $s0 para asegurarnos de que no se pierde $s3 en otra función
	jal 	imagen_pixel_addr	# saltamos a imagen_pixel_addr
	sb 	$s0, 0($v0)		# guardamos "color" ($s0) en la posición devuelta por imagen_pixel_addr ($v0)
	
	lw 	$s0, 0($sp)		# restauramos $s0
	lw	$ra, 4($sp)		# restauramos $ra
	addiu	$sp, $sp, 8		# liberamos el espacio de la pila
	jr 	$ra				
	
	# si no funciona comprobar las cosas que guarda y restaura de la pila
	
imagen_clean:		# ($a0, $a1) = (*img, fondo)
	# void imagen_clean(Imagen *img, Pixel fondo) {
 	#    for (int y = 0; y < img->alto; ++y) {
    	#       for (int x = 0; x < img->ancho; ++x) {
  	#           imagen_set_pixel(*img, x, y, fondo);
 	#       }
 	#    }
	# } 
	
	addiu	$sp, $sp, -28
	sw	$ra, 24($sp)
	sw	$s0, 20($sp)		
	sw	$s1, 16($sp)
	sw	$s2, 12($sp)
	sw	$s3, 8($sp)
	sw	$s4, 4($sp)
	sw	$s5, 0($sp)
	
	move	$s2, $a0
	move	$s3, $a1
	lw	$s4, 4($s2)		# carga img->alto en $s4
	lw	$s5, 0($s2)		# carga img->ancho en $s5
	
	# for (int y = 0; y < img->alto; ++y) {
	li 	$s0, 0			# int y = 0
B0_1:	bge  	$s0, $s4, B0_2		# si y >= img->alto salta el bucle
	
	# for (int x = 0; x < img->ancho; ++x)
	li	$s1, 0			# int x = 0
B0_3:	bge	$s1, $s5, B0_4		# si x >= img->ancho salta el bucle

	# imagen_set_pixel(*img, x, y, fondo)
	
	move	$a3, $a1
	move	$a1, $s1
	move	$a2, $s0
	jal 	imagen_set_pixel
	move 	$a0, $s2
	move	$a1, $s3
	
	addiu	$s1, $s1, 1		# ++x
	j	B0_3			# sigue el bucle
	# }
	
B0_4:	addiu	$s0, $s0, 1		# ++y
	j	B0_1
	# }
	
B0_2:	lw	$s5, 0($sp)
	lw	$s4, 4($sp)
	lw	$s3, 8($sp)
	lw	$s2, 12($sp)
	lw 	$s1, 16($sp)
	lw	$s0, 20($sp)
	lw	$ra, 24($sp)
	addiu	$sp, $sp, 28	
     	jr $ra
     	
     	
game_over:	
	# if (probar_pieza == 0) print ( 'GAME OVER' )
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)
	
	la	$a0, pieza_actual
	li	$a1, 8
	li	$a2, 0				
	jal	probar_pieza		# probar_pieza(Imagen* pieza, int x, int y)
	bnez 	$v0, B7_1		# salta el bucle si probar_pieza == 1
		
	la	$a0, pantalla
	la	$a1, end0	
	li	$a2, 0
	li	$a3, 6
	jal	imagen_dibuja_cadena	# imagenDibujaCadena(*img, cadena, x, y)
	
	la	$a0, pantalla
	la	$a1, end1	
	li	$a2, 0
	li	$a3, 7
	jal	imagen_dibuja_cadena	# imagenDibujaCadena(*img, cadena, x, y)
	
	la	$a0, pantalla
	la	$a1, end2	
	li	$a2, 0
	li	$a3, 8
	jal	imagen_dibuja_cadena	# imagenDibujaCadena(*img, cadena, x, y)
	
	la	$a0, pantalla
	la	$a1, end3	
	li	$a2, 0
	li	$a3, 9
	jal	imagen_dibuja_cadena	# imagenDibujaCadena(*img, cadena, x, y)
	
	la	$a0, pantalla
	la	$a1, end4	
	li	$a2, 0
	li	$a3, 10
	jal	imagen_dibuja_cadena	# imagenDibujaCadena(*img, cadena, x, y)
	
	la	$a0, pantalla
	la	$a1, end5	
	li	$a2, 0
	li	$a3, 11
	jal	imagen_dibuja_cadena	# imagenDibujaCadena(*img, cadena, x, y)
	
	jal 	clear_screen
	la	$a0, pantalla
	jal 	imagen_print
	jal 	read_character
	li 	$t0, 1
	sb 	$t0, acabar_partida
	
	
B7_1:	
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
	jr $ra


comrobar_linea:     

	la	$s0, campo		# $s0 = campo
	lw	$s1, 0($s0)  		# $s1 = campo->ancho
	lw	$s2, 4($s0)  		# $s2 = campo->alto
        
        # for (Int y = 0; y < campo->alto; i++)
        li	$s3, 0			# y = 0
B8_1:   bge	$s3, B8_4		# si no se cumple el bucle, salta a B8_1
        
        # for (Int x = 0; x < campo->ancho; i++)
        li	$s4, 0			# x = 0
B8_2:   bge	$s4, B8_3		# si no se cumple el bucle, salta a B8_2
	
	move 	$a0, $s0
	move	$a1, $s4
	move	$a2, $s3
	jal	imagen_get_pixel	# imagen_get_pixel($a0, $a1, $a2) = (img, x, y)	
        
        # }
B8_3:

        
        # }        
B8_4        
        
        
imagen_init:
	# void imagen_init(Imagen *img, int ancho, int alto, Pixel fondo) {
  	# 	img->ancho = ancho;
  	# 	img->alto = alto;
  	# 	imagen_clean(*img, fondo);
	# }
	
	addiu 	$sp, $sp, -4		# Hacemos hueco en la pila para guardar $ra
	sw 	$ra, 0($sp)
	
	sw	$a1, 0($a0)		# img->ancho = ancho
	sw	$a2, 4($a0)		# img->alto = alto
	
	move 	$a1, $a3		# Preparamos los parámetros para llamar a imagen_clean
	jal 	imagen_clean		
	
	lw	$ra, 0($sp)		# Restauramos la pila
	addiu	$sp, $sp, 4
	jr $ra

imagen_copy:
	# void imagen_copy(Imagen *dst, Imagen *src) {
 	#   dst->ancho = src->ancho;
  	#   dst->alto = src->alto;
  	#   for (int y = 0; y < src->alto; ++y) {
    	#      for (int x = 0; x < src->ancho; ++x) {
      	#         Pixel p = imagen_get_pixel(src, x, y);
      	#         imagen_set_pixel(dst, x, y, p);
    	#      }
  	#   }
	# }

	addiu	$sp, $sp, -28
	sw	$ra, 24($sp)
	sw	$s0, 20($sp)		
	sw	$s1, 16($sp)
	sw	$s2, 12($sp)
	sw	$s3, 8($sp)
	sw	$s4, 4($sp)
	sw	$s5, 0($sp)

	move	$s4, $a0		# Guardamos *dst en $s4 para usarlo posteriormente
	move	$s5, $a1		# Guardamos *src en $s4 para usarlo posteriormente

	lw	$s0, 0($s5)		# Cargamos src->ancho en $s0
	sw	$s0, 0($s4)		# Guardamos $s0 en dst->ancho
	
	lw	$s1, 4($s5)		# Cargamos src->alto en $s1
	sw 	$s1, 4($s4)		# Guardamos $s1 en dst->alto

	# for (int y = 0; y < src->alto; ++y) {
	li 	$s2, 0			# int y = 0
	# src->alto está en $s1
B1_1:	bge	$s2, $s1, B1_2		# si y >= src->alto salta el bucle

	# for (int x = 0; x < src->ancho; ++x) {
	li	$s3, 0			# int x = 0
	# src->ancho está en $s0
B1_3:	bge	$s3, $s0, B1_4		# si x >= src->ancho salta el bucle
	# Pixel p = imagen_get_pixel(src, x, y);
	move 	$a0, $s5
	move	$a1, $s3
	move	$a2, $s2
	jal 	imagen_get_pixel
	move	$a3, $v0		# guardamos p en $a3 para metérselo como parámetro a imagen_set_pixel	
	# imagen_set_pixel(dst, x, y, p);
	move	$a0, $s4
	move	$a1, $s3
	move	$a2, $s2
	jal imagen_set_pixel
	
	addiu	$s3, $s3, 1		# ++x
	j	B1_3			# sigue el bucle
	# }
	
B1_4:	addiu	$s2, $s2, 1		# ++y
	j	B1_1			# sigue el bucle
	# }
	
B1_2:	
	lw	$s5, 0($sp)
	lw	$s4, 4($sp)
	lw	$s3, 8($sp)
	lw	$s2, 12($sp)
	lw 	$s1, 16($sp)
	lw	$s0, 20($sp)
	lw	$ra, 24($sp)
	addiu	$sp, $sp, 28	
     	jr $ra	



imagen_print:				# $a0 = img
	# void imagen_print(Imagen *img) {
	#   for (int y = 0; y < img->alto; ++y) {
	#     for (int x = 0; x < img->ancho; ++x) {
	#       Pixel p = imagen_get_pixel(img, x, y);
	#       print_character(p);
	#     }
	#     print_character('\n');
	#   }
	# }
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
	# void imagen_dibuja_imagen(Imagen *dst, Imagen *src, int dst_x, int dst_y) {
  	#    for (int y = 0; y < src->alto; ++y) {
    	#       for (int x = 0; x < src->ancho; ++x) {
      	#          Pixel p = imagen_get_pixel(src, x, y);
      	#          if (p != PIXEL_VACIO) {
        #             imagen_set_pixel(dst, dst_x + x, dst_y + y, p);
      	#          }
    	#       }
  	#    }
	# }

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

	move	$s0, $a0		# $s0 = *dst
	move	$s1, $a1		# $s1 = *src
	move 	$s2, $a2		# $s2 = dst_x
	move 	$s3, $a3		# $s3 = dst_y
	lw	$s4, 4($s1)		# $s4 = src->alto
	lw	$s5, 0($s1)		# $s5 = src->ancho
	
	# for (int y = 0; y < src->alto; ++y) {
	li 	$s6, 0			# int y = 0
B2_1:	bge	$s6, $s4, B2_2		# si y >= src->alto salta el bucle
	# for (int x = 0; x < src->ancho; ++x) {
	li	$s7, 0			# int x = 0

B2_3:	bge	$s7, $s5, B2_4		# si x >= src->ancho salta el bucle
	
	# Pixel p = imagen_get_pixel(src, x, y);
	move 	$a0, $s1
	move	$a1, $s7
	move	$a2, $s6
	jal 	imagen_get_pixel
	
	# if (p != PIXEL_VACIO) {
	beqz   	$v0, B2_31
	
	# imagen_set_pixel(*dst, dst_x + x, dst_y + y, p);
	move 	$a0, $s0		# $a0 = dst	
	add	$a1, $s2, $s7		# $a1 = dst_x + x	
	add	$a2, $s3, $s6		# $a1 = dst_y + y
	move	$a3, $v0		# $s3 = p
	jal 	imagen_set_pixel
	# }

B2_31:	addiu	$s7, $s7, 1		# ++x
	j	B2_3			# sigue el bucle
	# }
	
B2_4:	addiu	$s6, $s6, 1		# ++y
	j	B2_1			# sigue el bucle
	# }

B2_2:
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
	
	# void imagen_dibuja_imagen_rotada(Imagen *dst, Imagen *src, int dst_x, int dst_y) {
  	#    for (int y = 0; y < src->alto; ++y) {
    	#       for (int x = 0; x < src->ancho; ++x) {
      	#          Pixel p = imagen_get_pixel(src, x, y);
      	#          if (p != PIXEL_VACIO) {
        #             imagen_set_pixel(dst, dst_x + src->alto - 1 - y, dst_y + x, p);
      	#          }
      	#       }
      	#    }
      	# }

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

	move	$s0, $a0		# $s0 = *dst
	move	$s1, $a1		# $s1 = *src
	move 	$s2, $a2		# $s2 = dst_x
	move 	$s3, $a3		# $s3 = dst_y
	lw	$s4, 4($s1)		# $s4 = src->alto
	lw	$s5, 0($s1)		# $s5 = src->ancho
	
	# for (int y = 0; y < src->alto; ++y) {
	li 	$s6, 0			# int y = 0
B3_1:	bge	$s6, $s4, B3_2		# si y >= src->alto salta el bucle
	# for (int x = 0; x < src->ancho; ++x) {
	li	$s7, 0			# int x = 0

B3_3:	bge	$s7, $s5, B3_4		# si x >= src->ancho salta el bucle
	
	# Pixel p = imagen_get_pixel(src, x, y);
	move 	$a0, $s1
	move	$a1, $s7
	move	$a2, $s6
	jal 	imagen_get_pixel
	
	# if (p != PIXEL_VACIO) {
	beqz   	$v0, B3_31
	
	
	# imagen_set_pixel(dst, dst_x + src->alto - 1 - y, dst_y + x, p);
	move 	$a0, $s0		# $a0 = dst	
	add	$a1, $s2, $s4		# $a1 = dst_x + src->alto
	subi 	$a1, $a1, 1 		# $a1 = $a1 - 1
	sub 	$a1, $a1, $s6		# $a1 = $a1 - y
	add	$a2, $s3, $s7		# $a1 = dst_y + x
	move	$a3, $v0		# $a3 = p
	jal imagen_set_pixel
	# }
	

B3_31:	addiu	$s7, $s7, 1		# ++x
	j	B3_3			# sigue el bucle
	# }
	
B3_4:	addiu	$s6, $s6, 1		# ++y
	j	B3_1			# sigue el bucle
	# }

B3_2:
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
	
	la	$a0, pantalla
	la	$a1, str003	
	li	$a2, 0
	li	$a3, 0
	jal	imagen_dibuja_cadena	# imagenDibujaCadena(*img, cadena, x, y)
	
	lw	$a0, puntuacion_actual
	li	$a1, 10			
	la	$a2, cadena_puntos	# dirección donde guardaremos la cadena
	jal	integer_to_string_v4
	
	la	$a0, pantalla
	la	$a1, cadena_puntos
	li	$a2, 12
	li	$a3, 0
	jal 	imagen_dibuja_cadena
	
	jal 	game_over
	
	la	$a0, pantalla
	jal	imagen_print		# imagen_print(pantalla)
	lw	$s1, 0($sp)
	lw	$s2, 4($sp)
	lw	$ra, 8($sp)
	addiu	$sp, $sp, 12
	jr	$ra

nueva_pieza_actual:
	# void nueva_pieza_actual(void) {
  	#    Imagen *elegida = pieza_aleatoria();
  	#    imagen_copy(pieza_actual, elegida);
  	#    pieza_actual_x = 8;
  	#    pieza_actual_y = 0;
	# }
	
	addiu	$sp, $sp, -4		
	sw	$ra, 0($sp)
	
	jal 	pieza_aleatoria		# $v0 == Imagen *elegida
	
	la	$a0, pieza_actual	# Cargamos la dirección de pieza_actual en $a0 para llamar a imagen_copy
	move 	$a1, $v0		# Cargamos *elegida en $a1 para llamar a imagen_copy
	jal	imagen_copy		
	
	li	$t0, 8
	sw 	$t0, pieza_actual_x	# pieza_actual_x = 8;
	li	$t1, 0
	sw 	$t1, pieza_actual_y	# pieza_actual_y = 0;
	
	lw	$ra, 0($sp)
	addiu	$sp, $sp, 4
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
	# bool intentar_movimiento(int x, int y) {
  	# if (probar_pieza(pieza_actual, x, y)) {
    	#    pieza_actual_x = x;
    	#    pieza_actual_y = y;
    	#    return true;
 	# }
  	# return false;
	# }
	
	addiu	$sp, $sp, -12
	sw	$ra, 8($sp)
	sw	$s0, 4($sp)
	sw	$s1, 0($sp)
	
	move	$s0, $a0		# $s0 = x
	move	$s1, $a1		# $s1 = y
	
	la	$a0, pieza_actual
	move	$a1, $s0
	move	$a2, $s1
	jal 	probar_pieza
	
	# if (probar_pieza(pieza_actual, x, y)) {
	beqz 	$v0, B13_1		# si no se cumple la condición del if, saltamos a B13_1
	sw	$s0, pieza_actual_x	# pieza_actual_x = x
	sw	$s1, pieza_actual_y	# pieza_actual_y = y
	li	$v0, 1			# return 1
	j 	B13_2
	# }
	
B13_1:  li	$v0, 0			# return 0
	
B13_2:	lw	$s1, 0($sp)
	lw	$s0, 4($sp)
	lw	$ra, 8($sp)
	addiu	$sp, $sp, 12
	jr	$ra

bajar_pieza_actual:
	# void bajar_pieza_actual(void) {
  	#    if (!intentar_movimiento(pieza_actual_x, pieza_actual_y + 1)) {
    	#       imagen_dibuja_imagen(campo, pieza_actual, pieza_actual_x, pieza_actual_y);
    	#       nueva_pieza_actual();
  	#    }
	# }
	
	addiu	$sp, $sp, -4
	sw	$ra, 0($sp)	
	
	lw	$a0, pieza_actual_x	# perparamos los parámetros para llamar a intentar_movimiento
	lw	$a1, pieza_actual_y
	addi 	$a1, $a1, 1
	
	jal intentar_movimiento
	# if (!intentar_movimiento(pieza_actual_x, pieza_actual_y + 1)) {
	bnez  	$v0, B14_1		# si no se cumple la condición salta el bucle
	
	la	$a0, campo
	la	$a1, pieza_actual
	lw	$a2, pieza_actual_x
	lw	$a3, pieza_actual_y
	jal 	imagen_dibuja_imagen
	jal	nueva_pieza_actual
	
	lw	$t9, puntuacion_actual
	addi	$t9, $t9, 1
	sw	$t9, puntuacion_actual
	
	# }
B14_1:	lw	$ra, 0($sp)
	addiu 	$sp, $sp, 4
	jr	$ra

intentar_rotar_pieza_actual:
	# void intentar_rotar_pieza_actual(void) {
  	#    Imagen *pieza_rotada = imagen_auxiliar;
  	#    imagen_init(pieza_rotada, pieza_actual->alto, pieza_actual->ancho, PIXEL_VACIO);
  	#    imagen_dibuja_imagen_rotada(pieza_rotada, pieza_actual, 0, 0);
  	#    if (probar_pieza(pieza_rotada, pieza_actual_x, pieza_actual_y)) {
   	#       imagen_copy(pieza_actual, pieza_rotada);
  	#    }
	# }

	addiu 	$sp, $sp, -8
	sw	$ra, 4($sp)
	sw	$s0, 0($sp)


	la	$s0, imagen_auxiliar	# Imagen *pieza_rotada = imagen_auxiliar
	
	move	$a0, $s0
	la 	$t0, pieza_actual	# cargamos pieza_actual en $t0 para sacar pieza_actual->alto
	lw	$a1, 4($t0)		
	lw	$a2, 0($t0)
	move	$a3, $zero
	jal 	imagen_init
	
	move	$a0, $s0
	la	$a1, pieza_actual
	move	$a2, $zero
	move	$a3, $zero
	jal 	imagen_dibuja_imagen_rotada
	
	move	$a0, $s0
	lw	$a1, pieza_actual_x
	lw	$a2, pieza_actual_y
	jal	probar_pieza
	# if (probar_pieza(pieza_rotada, pieza_actual_x, pieza_actual_y)) {
	beqz	$v0, B15_1
	
	la	$a0, pieza_actual
	move	$a1, $s0
	jal	imagen_copy		# imagen_copy(pieza_actual, pieza_rotada)
	# }
B15_1:	lw	$s0, 0($sp)
	lw	$ra, 4($sp)
	addiu	$sp, $sp, 8
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

integer_to_string_v4:			# ($a0, $a1, $a2) = (n, base, buf)
	
	move    $t0, $a2		# char *p = buff
	beqz 	$a0, B4_22		# Si es 0 pasa directamente a la etiqueda B4_22
	li    $t5, 10
	# for (int i = |n|; i > 0; i = i / base) {
        abs	$t1, $a0		# int i = |n|
        
B4_1:   blez	$t1, B4_2		# si i <= 0 salta el bucle
	div	$t1, $a1		# i / base
	mflo	$t1			# i = i / base
	mfhi	$t2			# d = i % base  
  	blt    $t2, $t5, B4_11  # if d < 10 then B4_11
  	bge    $t2, $t5, B4_12  # if d >= 10 then B4_12
B4_11:  addiu	$t2, $t2, '0'		# d + '0'
        sb	$t2, 0($t0)		# *p = $t2 
        addiu	$t0, $t0, 1		# ++p
        j	B4_1			# sigue el bucle
        # }     
       	# Los valores > 9 se pasan a su correspondiente valor A, B...  
B4_12: 	sub 	$t2, $t2, $t5		# d - 10
	addiu	$t2, $t2, 'A'		# d + 'A'  
        sb	$t2, 0($t0)		# *p = $t2 
        addiu	$t0, $t0, 1		# ++p
        j	B4_1			# sigue el bucle
        # }    
        
B4_2: 	bgtz 	$a0, B4_21  		# si n > 0 salta a B4_21

	li    	$t4, '-'    		# cargamos en $t4 '-'
	sb  	$t4, 0($t0)
        addiu	$t0, $t0, 1

B4_21: 	sb	$zero, 0($t0)		# *p = '\0'

	# Precondición bucle ordenar	
	# $t0 es el puntero de la última posición y $a2 la posición del primer número
	subi 	$t0, $t0, 1 		# Coloca el puntero $t0 una posición anterior
	move 	$t1, $a2		# Usamos $t1 en vez de $a2
	
	# Bucle para ordenar. Los dos punteros son $t1 (L) y $t0 (R)
B4_A:	bge 	$t1, $t0, B4_4		# Termina el bucle cuando $t1 sea mayor o igual que $t0
	lb 	$t2, 0($t1)		# Guarda el contenido de ($t1) en $t2
	lb 	$t3, 0($t0)		# Guarda el contenido de ($t0) en $t3
	sb 	$t2, 0($t0)		# Guarda el contenido de $t2 en ($t0)
	sb 	$t3, 0($t1)		# Guarda el contenido de $t3 en ($t1)	
	addiu	$t1, $t1, 1		# Incrementa el puntero $t1
	subiu	$t0, $t0, 1		# Decrementa el puntero $t0
	j 	B4_A			# Repite el bucle

B4_4:	jr	$ra

B4_22:  li    	$t4, '0'
        sb  	$t4, 0($t0)
        addiu	$t0, $t0, 1
        sb	$zero, 0($t0)
        j B4_4


imagen_dibuja_cadena:        		#($a0,$a1, $a2,$a3) = (pantalla, dircadena, pos x, pos y)
	addiu	$sp, $sp, -24
	sw	$s0, 20($sp)
	sw	$s1, 16($sp)
	sw	$s2, 12($sp)
	sw	$s3, 8($sp)
	sw	$s4, 4($sp)
	sw	$ra, 0($sp)
	
	move	$s0, $a0		# $s0 = pantalla	= *img
	move	$s1, $a1		# $s1 = dircadena
	move	$s2, $a2		# $s2 = pos x
	move	$s3, $a3		# $s3 = pos y
	
B5_1:	lb	$s4, 0($s1)		# Cargamos el carácter de la cadena ($s1) en $s4
	beqz	$s4, B5_2		# Si el carácter es \0 termina el bucle

	move	$a0, $s0		# $a0 = pantalla 	
	move 	$a1, $s2		# $a1 = $s2
	move	$a2, $s3		# $a2 = $s3
	move	$a3, $s4		# $a3 = Pixel (carácter)
	jal 	imagen_set_pixel	# imagen_set_pixel(Imagen *img, int x, int y, Pixel color)

	addi 	$s1, $s1, 1		# Siguiente pixel
	addi 	$s2, $s2, 1		# x++
	j	B5_1
	
B5_2:	lw	$s0, 20($sp) 
	lw	$s1, 16($sp)
	lw	$s2, 12($sp)
	lw	$s3, 8($sp)
	lw	$s4, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 24
	jr	$ra













