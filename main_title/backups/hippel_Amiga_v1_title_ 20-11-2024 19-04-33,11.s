; replay hippel sur Jaguar
;
; replay au 68000
;
; en utilisant le desassemblage de APMIX.IMG

song=1		;1 uniquement
flag_display_infos=1
mixage=1
lecture_valeurs_paula=1

channel_1		.equ		1
channel_2		.equ		1
channel_3		.equ		1
channel_4		.equ		1

volume_music=256				; 0-256
volume_SFX=80					; 0-256

;-------------------------
;CC (Carry Clear) = %00100
;CS (Carry Set)   = %01000
;EQ (Equal)       = %00010
;MI (Minus)       = %11000
;NE (Not Equal)   = %00001
;PL (Plus)        = %10100
;HI (Higher)      = %00101
;T (True)         = %00000
;-------------------------

COULEUR_MARQUEUR_vert_vif=$FF000000
COULEUR_MARQUEUR_rouge_vif=$00FF0000
COULEUR_MARQUEUR_bleu_vif=$000000FF
COULEUR_MARQUEUR_cyan=$FF0000FF
COULEUR_MARQUEUR_violet=$00FF00FF
COULEUR_MARQUEUR_jaune=$FFFF0000
COULEUR_MARQUEUR_blanc=$FFFF00FF

	include	"jaguar.inc"
CLEAR_BSS			.equ			1									; 1=efface toute la BSS jusqu'a la fin de la ram utilisée


; ----------------------------
; parametres affichage
;ob_liste_originale			equ		(ENDRAM-$4000)							; address of list (shadow)
ob_list_courante			equ		((ENDRAM-$4000)+$2000)				; address of read list
nb_octets_par_ligne			equ		320
nb_lignes					equ		256

curseur_Y_min		.equ		8



.opt "~Oall"

.text

			.68000

relaunch_all:
	move.l		#$70007,G_END
	move.l		#$70007,D_END
	move.l		#INITSTACK-128, sp	

; routines de debug
	lea			bus_error_68000,a0
	move.l		a0,$0008.w
	move.l		#address_error_68000,$C.w

; init curseur / relaunch test
	move.w		#25,couleur_char
	move.w		#0,curseur_x
	move.w		#curseur_Y_min,curseur_y
; init dsp volumes for relaunch test
	move.l		#volume_SFX,DSP_volume_SFX
	move.l		#volume_music,DSP_volume_music


	
	move.w		#%0000011011000111, VMODE			; 320x256
	
	move.w		#$100,JOYSTICK


	move.w		#801,VI			; stop VI

; clear BSS
	lea			DEBUT_BSS,a0
	lea			FIN_RAM,a1
	moveq		#0,d0
	
boucle_clean_BSS:
	move.b		d0,(a0)+
	cmp.l		a0,a1
	bne.s		boucle_clean_BSS
; clear stack
	lea			INITSTACK-100,a0
	lea			INITSTACK,a1
	moveq		#0,d0
	
boucle_clean_BSS2:
	move.b		d0,(a0)+
	cmp.l		a0,a1
	bne.s		boucle_clean_BSS2

    bsr     InitVideo               	; Setup our video registers.

	jsr     copy_olist              	; use Blitter to update active list from shadow

	move.l	#ob_list_courante,d0					; set the object list pointer
	swap	d0
	move.l	d0,OLP

	lea		CLUT,a2
	move.l	#255-2,d7
	moveq	#0,d0
	
copie_couleurs:
	move.w	d0,(a2)+
	addq.l	#5,d0
	dbf		d7,copie_couleurs

	lea		CLUT+2,a2
	move.w	#$F00F,(a2)+


	moveq	#song,d0
	jsr		WODTFMX	





	move.l  #VBL,LEVEL0     	; Install 68K LEVEL0 handler
	move.w  a_vde,d0                	; Must be ODD
	;sub.w   #16,d0
	ori.w   #1,d0
	move.w  d0,VI

	move.w  #%01,INT1                 	; Enable video interrupts 11101


	;and.w   #%1111100011111111,sr				; 1111100011111111 => bits 8/9/10 = 0
	and.w   #$f8ff,sr

; CLS
	;moveq	#0,d0
	;bsr		print_caractere

; init DSP

	lea		chaine_HIPPEL,a0
	bsr		print_string
; ligne suivant
	moveq	#10,d0
	bsr		print_caractere
	


	
	
	jsr		PAULA_init
	move.w		#0,compteur_frame_music

	move.w		#85,couleur_char

; replay frequency
	lea			chaine_replay_frequency,a0
	bsr			print_string

	move.l		DSP_frequence_de_replay_reelle_I2S,d0
	bsr			print_nombre_5_chiffres

	lea			chaine_Hz_init_LSP,a0
	bsr			print_string
	
	lea			chaine_frequency_correction,a0
	bsr			print_string
	
	move.l		#PAULA_corretion_frequence,d0
	bsr			print_nombre_3_chiffres
; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

; ligne suivant
	moveq	#10,d0
	bsr		print_caractere


	lea			chaine_replay_songnumber,a0
	bsr			print_string
	
	move.l		#song,d0
	bsr			print_nombre_3_chiffres
	
; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

				jsr			WODTFMX+4
				bsr			copie_Paula_to_data_stack
				jsr			WODTFMX+4
				bsr			copie_Paula_to_data_stack
				;move.l		#flag_prise_en_compte_valeurs_PAULA,Paula_flag_Tick_50Hz
	

	
	
	lea			chaine_replay_volumes,a0
	bsr			print_string
	move.l		DSP_volume_music,d0
	bsr			print_nombre_3_chiffres
	move.l	#' ',d0
	bsr		print_caractere
	move.l		DSP_volume_SFX,d0
	bsr			print_nombre_3_chiffres
; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

	
	move.w		#145,couleur_char

				;jsr			APMIX_entry_point+4



;----------------
main:
				;cmp.l		#flag_timer_50HZ_OK ,Paula_flag_Tick_50Hz
				;bne.s		main




;				.if				flag_display_infos=0
				;move.w		#$7700,BG
; attente fin dsp mixing
;.wait:
;				cmp.l		#flag_en_attente_timer_50HZ ,Paula_flag_Tick_50Hz
;				bne.s		.wait
;				.endif

				;move.w		#$0000,BG
				
				.if				flag_display_infos=1
				bsr			display_infos
				.endif
	
				move.w			compteur_frame_music,d0
				cmp.w			#(50*5),d0
				blt.s			.1
				; stop VBL
				move.l			#VBL_empty,LEVEL0
				; volumes = 0
				move.l		#0,DSP_volume_SFX
				move.l		#0,DSP_volume_music

				; stop DSP
				move.l			#DSP_STOP_flag_STOP_NOW,DSP_flag_STOP
				
				; wait for DSP to fully stop
.2:
					move.l		#flag_timer_50HZ_OK,Paula_flag_Tick_50Hz
					move.l  	D_CTRL,d0               ; Wait for complete
					andi.l  		#$1,d0
					bne.s   		.2
					
					move.l		#0,L_I2S
					move.l		#0,L_I2S+4
	
	
					jmp			relaunch_all
	
.1:	
				bra.s		main
;----------------

plays_speech_sfx:
; d0=sample number
; d1=sfx channel ( 0=left / 1=right)
; speech+8 +(numéro*24) : offset debug, taille
; volume = 63 / period = $240
			lea			speech+8,a0
			mulu			#24,d0
			lea			(a0,d0.w),a0
			move.l		(a0),d3
			move.l		4(a0),d5
			and.w		#$FFFE,d3
			and.w		#$FFFE,d5
			moveq		#0,d4
			lea			PAULA_SFX_left,a1
			cmp.w		#1,d1
			bne.s		.left
			lea			PAULA_SFX_right,a1
.left:
			move.l		12(a1),d6
			cmp.w		#0,d6
			bne.s		.exit
			move.l		#63,d6
			move.l		#$240,d7
			lea			speech+8+(24*14),a2
			add.l			a2,d3
			lsl.l			#8,d3
			lsl.l			#nb_bits_virgule_offset-8,d3		; location << nb_bits_virgule_offset
			add.l			a2,d5
			lsl.l			#8,d5
			lsl.l			#nb_bits_virgule_offset-8,d5		; end << nb_bits_virgule_offset

			movem.l	d3-d7,(a1)
.exit:			
			rts

;PAULA_SFX_left:
;PAULA_sample_location_sfx1:				dc.l			silence<<nb_bits_virgule_offset								;  0 : interne
;PAULA_sample_location_virgule_sfx1:	dc.l			0																				;  1 : interne
;PAULA_sample_end_sfx1:						dc.l			(silence+2)<<nb_bits_virgule_offset						;  2 : interne
;PAULA_volume_sfx1:								dc.l			0																				;  3 : volume
;PAULA_period_sfx1:								dc.l			$110																;  4 :	period	; uniquement a virgule car frequence de replay > 28800 ( maxi Amiga )




Hippel_replay_asynchronous:
				move.l		table_buffers_paula_asynchrones__WRITE,d0
				move.l		table_buffers_paula_asynchrones__READ,d1
				sub.w		d1,d0				; WRITE - READ
				and.w		#%111,d0			; loop sur 8
				cmp.w		#3,d0
				bgt.s			main_no_play
				
				jsr			WODTFMX+4
				bsr			copie_Paula_to_data_stack
				;move.l		#flag_prise_en_compte_valeurs_PAULA,Paula_flag_Tick_50Hz
				addq.w		#1,compteur_frame_music
main_no_play:				
				rts
compteur_frame_music:			dc.w				0



copie_Paula_to_data_stack:

		move.l				table_buffers_paula_asynchrones__WRITE,d0
		move.l				d0,d1
		lsl.w					#2,d0			; *4
		lea					table_buffers_paula_asynchrones,a0
		move.l				(a0,d0.w),a2
		lea					Paula_custom,a1
		movem.l			(a1)+,d0/d2-d7/a0/a3-a6			; 12*4
		movem.l			d0/d2-d7/a0/a3-a6,(a2)
		movem.l			(a1)+,d0/d2-d4							; 4*4
		movem.l			d0/d2-d4,(12*4)(a2)
	
		addq.w				#1,d1
		and.w				#%111,d1			; loop on 8
		move.l				d1,table_buffers_paula_asynchrones__WRITE

		rts

; ----------- display infos --------
display_infos:
	.if			channel_1=1
; pointeur sample en cours / interne
	move.l	PAULA_sample_location0,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample en cours / interne
	move.l	PAULA_sample_location_virgule0,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; end 0 / interne
	move.l	PAULA_sample_end0,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; PAULA_PAULA_increment0
	move.l	PAULA_increment0,d0
	bsr		print_nombre_hexa_8_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere


; PAULA_volume0
	move.l	PAULA_volume0,d0
	bsr		print_nombre_hexa_2_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


; pointeur sample repeat / externe
	move.l	PAULA_repeat_location0,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample repeat fin / externe
	move.l	PAULA_repeat_end0,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere
	.endif

; voie B
	.if			channel_2=1
; pointeur sample en cours / interne
	move.l	PAULA_sample_location1,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample en cours / interne
	move.l	PAULA_sample_location_virgule1,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; end 0 / interne
	move.l	PAULA_sample_end1,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; PAULA_PAULA_increment0
	move.l	PAULA_increment1,d0
	bsr		print_nombre_hexa_8_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

; PAULA_volume0
	move.l	PAULA_volume1,d0
	bsr		print_nombre_hexa_2_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


; pointeur sample repeat / externe
	move.l	PAULA_repeat_location1,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample repeat fin / externe
	move.l	PAULA_repeat_end1,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere
	.endif
	
; voie C
	.if		channel_3=1
; pointeur sample en cours / interne
	move.l	PAULA_sample_location2,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample en cours / interne
	move.l	PAULA_sample_location_virgule2,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; end 0 / interne
	move.l	PAULA_sample_end2,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; PAULA_PAULA_increment0
	move.l	PAULA_increment2,d0
	bsr		print_nombre_hexa_8_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

; PAULA_volume0
	move.l	PAULA_volume2,d0
	bsr		print_nombre_hexa_2_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


; pointeur sample repeat / externe
	move.l	PAULA_repeat_location2,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample repeat fin / externe
	move.l	PAULA_repeat_end2,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere
	.endif

; voie D
	.if		channel_4=1
; pointeur sample en cours / interne
	move.l	PAULA_sample_location3,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample en cours / interne
	move.l	PAULA_sample_location_virgule3,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; end 0 / interne
	move.l	PAULA_sample_end3,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; PAULA_PAULA_increment0
	move.l	PAULA_increment3,d0
	bsr		print_nombre_hexa_8_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

; PAULA_volume0
	move.l	PAULA_volume3,d0
	bsr		print_nombre_hexa_2_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


; pointeur sample repeat / externe
	move.l	PAULA_repeat_location3,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample repeat fin / externe
	move.l	PAULA_repeat_end3,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere
	.endif

;SFX
	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

; pointeur sample en cours / interne
	move.l	PAULA_sample_location_sfx1,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; end 0 / interne
	move.l	PAULA_sample_end_sfx1,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; PAULA_PAULA_increment0
	move.l	PAULA_period_sfx1,d0
	bsr		print_nombre_hexa_8_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

; PAULA_volume0
	move.l	PAULA_volume_sfx1,d0
	bsr		print_nombre_hexa_2_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


; pointeur sample repeat / externe
	move.l	PAULA_repeat_location_sfx1,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample repeat fin / externe
	move.l	PAULA_repeat_end_sfx1,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

; pointeur sample en cours / interne
	move.l	PAULA_sample_location_sfx2,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; end 0 / interne
	move.l	PAULA_sample_end_sfx2,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; PAULA_PAULA_increment0
	move.l	PAULA_period_sfx2,d0
	bsr		print_nombre_hexa_8_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


	; ligne suivant
	moveq	#10,d0
	bsr		print_caractere

; PAULA_volume0
	move.l	PAULA_volume_sfx2,d0
	bsr		print_nombre_hexa_2_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere


; pointeur sample repeat / externe
	move.l	PAULA_repeat_location_sfx2,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere

; virgule sample repeat fin / externe
	move.l	PAULA_repeat_end_sfx2,d0
	lsr.l		#8,d0
	lsr.l		#nb_bits_virgule_offset-8,d0
	bsr		print_nombre_hexa_6_chiffres
; 
	move.l	#' ',d0
	bsr		print_caractere



	; retour a la ligne	 au dessus
	.if			channel_1=1
	.rept			2
	moveq	#8,d0
	bsr		print_caractere
	.endr
	.endif
	.if			channel_2=1
	.rept			2
	moveq	#8,d0
	bsr		print_caractere
	.endr
	.endif
	.if			channel_3=1
	.rept			2
	moveq	#8,d0
	bsr		print_caractere
	.endr
	.endif
	.if			channel_4=1
	.rept			2
	moveq	#8,d0
	bsr		print_caractere
	.endr
	.endif
; SFX
	.rept			4
	moveq	#8,d0
	bsr		print_caractere
	.endr


	rts

;-----------------------------------------------------------------------------------
;--------------------------
; VBL

VBL:
; vbl interrupt, but also DSP to 68000 interrupt
; 
                movem.l 	d0-d7/a0-a6,-(a7)
                bsr     copy_olist              	; use Blitter to update active list from shadow
                addq.l	#1,vbl_counter
				
				bsr			Hippel_replay_asynchronous				
; test keys / pad
; xxxxxxCx xxBx2580 147*oxAP 369#RLDU
				move.l		DSP_pad1,d0
				move.l		d0,d1
				and.l			#U235SE_BUT_A,d1
				beq.s		.pas_button_A
				moveq		#0,d0			; sample=0
				moveq		#0,d1			; left
				bsr		plays_speech_sfx
.pas_button_A:
				move.l		d0,d1
				and.l			#U235SE_BUT_B,d1
				beq.s		.pas_button_B
				moveq		#1,d0			; sample=1
				moveq		#1,d1			; right
				bsr		plays_speech_sfx
.pas_button_B:
				move.l		d0,d1
				and.l			#U235SE_BUT_C,d1
				beq.s		.pas_button_C
				moveq		#2,d0			; sample=2
				moveq		#0,d1			; left
				bsr		plays_speech_sfx
.pas_button_C:
				
				
				
VBL_exit:
                movem.l (a7)+,d0-d7/a0-a6
VBL_empty:
                move.w		 	 #$101,INT1              	; Signal we're done						= $F000E0		$101 = clear VI
				move.w  	#$0,INT2						; The bus priorities restored = $F000E2
               rte



; ---------------------------------------
; print pads status 
; Pads : mask = xxxxxxCx xxBx2580 147*oxAP 369#RLDU
print_pads_status:
	
	move.l		DSP_pad1,d1
	lea			string_pad_status,a0
	move.l		#31,d6

.boucle:	
	moveq		#0,d0
	btst.l		d6,d1
	beq.s		.print_space
	move.b		(a0)+,d0
	bsr			print_caractere
	bra.s		.ok
.print_space:
	move.b		#'.',d0
	bsr			print_caractere
	lea			1(a0),a0
.ok:
	dbf			d6,.boucle

; ligne suivante
	moveq		#10,d0
	bsr			print_caractere
	
print_pads_status_pad2:
; pad2
	move.l		DSP_pad2,d1
	lea			string_pad_status,a0
	move.l		#31,d6

.boucle2:	
	moveq		#0,d0
	btst.l		d6,d1
	beq.s		.print_space2
	move.b		(a0)+,d0
	bsr			print_caractere
	bra.s		.ok2
.print_space2:
	move.b		#'.',d0
	bsr			print_caractere
	lea			1(a0),a0
.ok2:
	dbf			d6,.boucle2

; ligne suivante
	moveq		#10,d0
	bsr			print_caractere
	

	rts

string_pad_status:		dc.b		"......CE..BD2580147*oFAp369#RLDU"
		even

; ---------------------------------------
; imprime une chaine terminée par un zéro
; a0=pointeur sur chaine
print_string:
	movem.l d0-d7/a0-a6,-(a7)	

print_string_boucle:
	moveq	#0,d0
	move.b	(a0)+,d0
	cmp.w	#0,d0
	bne.s	print_string_pas_fin_de_chaine
	movem.l (a7)+,d0-d7/a0-a6
	rts
print_string_pas_fin_de_chaine:
	bsr		print_caractere
	bra.s	print_string_boucle

; ---------------------------------------
; imprime un nombre HEXA de 2 chiffres
print_nombre_hexa_2_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	lea		convert_hexa,a0
	move.l		d0,d1
	divu		#16,d0
	and.l		#$F,d0			; limite a 0-15
	move.l		d0,d2
	mulu		#16,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	move.l		d1,d0
	and.l		#$F,d0			; limite a 0-15
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts
	
convert_hexa:
	dc.b		48,49,50,51,52,53,54,55,56,57
	dc.b		65,66,67,68,69,70
	even
	
; ---------------------------------------
; imprime un nombre de 2 chiffres
print_nombre_2_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	cmp.l		#0,d0
	beq.s		.zap
	add.l		#48,d0
	bsr			print_caractere
.zap:
	move.l		d1,d0
	add.l		#48,d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts

; ---------------------------------------
; imprime un nombre de 3 chiffres
print_nombre_3_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1

	divu		#100,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#100,d2
	sub.l		d2,d1
	cmp.l		#0,d0
	beq.s		.zap
	add.l		#48,d0
	bsr			print_caractere
.zap:
	move.l		d1,d0	
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere
	
	move.l		d1,d0
	add.l		#48,d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts


; ---------------------------------------
; imprime un nombre de 2 chiffres , 00
print_nombre_2_chiffres_force:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere
	move.l		d1,d0
	add.l		#48,d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts

; ---------------------------------------
; imprime un nombre de 4 chiffres HEXA
print_nombre_hexa_4_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1
	lea		convert_hexa,a0

	divu		#4096,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#4096,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere

	move.l		d1,d0
	divu		#256,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#256,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere


	move.l		d1,d0
	divu		#16,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#16,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	move.l		d1,d0
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts

; ---------------------------------------
; imprime un nombre de 6 chiffres HEXA ( pour les adresses memoire)
print_nombre_hexa_6_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	
	move.l		d0,d1
	lea		convert_hexa,a0

	move.l		d1,d0
	swap		d0
	and.l		#$F0,d0
	divu		#16,d0
	and.l		#$F,d0
	move.b		(a0,d0.w),d0
	and.l		#$FF,d0
	bsr			print_caractere

	move.l		d1,d0
	swap		d0
	and.l		#$F,d0
	move.b		(a0,d0.w),d0
	and.l		#$FF,d0
	bsr			print_caractere

	and.l		#$FFFF,d1
	move.l		d1,d0
	divu		#4096,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#4096,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere

	move.l		d1,d0
	divu		#256,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#256,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere


	move.l		d1,d0
	divu		#16,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#16,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	move.l		d1,d0
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts

; ---------------------------------------
; imprime un nombre de 8 chiffres HEXA ( pour les adresses memoire et les données en 16:16)
print_nombre_hexa_8_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	
	move.l		d0,d1
	lea		convert_hexa,a0

	move.l		d1,d0
	swap		d0
	and.l		#$F000,d0
	divu		#4096,d0
	and.l		#$F,d0
	move.b		(a0,d0.w),d0
	and.l		#$FF,d0
	bsr			print_caractere



	move.l		d1,d0
	swap		d0
	and.l		#$F00,d0
	divu		#256,d0
	and.l		#$F,d0
	move.b		(a0,d0.w),d0
	and.l		#$FF,d0
	bsr			print_caractere


	move.l		d1,d0
	swap		d0
	and.l		#$F0,d0
	divu		#16,d0
	and.l		#$F,d0
	move.b		(a0,d0.w),d0
	and.l		#$FF,d0
	bsr			print_caractere

	move.l		d1,d0
	swap		d0
	and.l		#$F,d0
	move.b		(a0,d0.w),d0
	and.l		#$FF,d0
	bsr			print_caractere

	and.l		#$FFFF,d1
	move.l		d1,d0
	divu		#4096,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#4096,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere

	move.l		d1,d0
	divu		#256,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#256,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere


	move.l		d1,d0
	divu		#16,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#16,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	move.l		d1,d0
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts


; ---------------------------------------
; imprime un nombre de 4 chiffres
print_nombre_4_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1

	divu		#1000,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#1000,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere

	move.l		d1,d0
	divu		#100,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#100,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere


	move.l		d1,d0
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere
	move.l		d1,d0
	add.l		#48,d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts

; ---------------------------------------
; imprime un nombre de 5 chiffres
print_nombre_5_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1

	divu		#10000,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10000,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere

	move.l		d1,d0
	divu		#1000,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#1000,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere

	move.l		d1,d0
	divu		#100,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#100,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere


	move.l		d1,d0
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere
	move.l		d1,d0
	add.l		#48,d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts


; -----------------------------
; copie un caractere a l ecran
; d0.w=caractere

print_caractere:
	movem.l d0-d7/a0-a6,-(a7)



	cmp.b	#00,d0
	bne.s	print_caractere_pas_CLS
	move.l	#ecran1,A1_BASE			; = DEST
	move.l	#$0,A1_PIXEL
	move.l	#PIXEL16|XADDPHR|PITCH1,A1_FLAGS
	move.l	#ecran1+320*100,A2_BASE			; = source
	move.l	#$0,A2_PIXEL
	move.l	#PIXEL16|XADDPHR|PITCH1,A2_FLAGS
	
	move.w	#$00,B_PATD
	

	moveq	#0,d0
	move.w	#nb_octets_par_ligne,d0
	lsr.w	#1,d0
	move.w	#nb_lignes,d1
	mulu	d1,d0
	swap	d0
	move.w	#1,d0
	swap	d0
	;move.w	#65535,d0
	move.l	d0,B_COUNT
	move.l	#LFU_REPLACE|SRCEN|PATDSEL,B_CMD


	movem.l (a7)+,d0-d7/a0-a6
	rts
	
print_caractere_pas_CLS:

	cmp.b	#10,d0
	bne.s	print_caractere_pas_retourchariot
	move.w	#0,curseur_x
	add.w	#8,curseur_y
	movem.l (a7)+,d0-d7/a0-a6
	rts

print_caractere_pas_retourchariot:
	cmp.b	#09,d0
	bne.s	print_caractere_pas_retourdebutligne
	move.w	#0,curseur_x
	movem.l (a7)+,d0-d7/a0-a6
	rts

print_caractere_pas_retourdebutligne:
	cmp.b	#08,d0
	bne.s	print_caractere_pas_retourdebutligneaudessus
	move.w	#0,curseur_x
	sub.w	#8,curseur_y
	movem.l (a7)+,d0-d7/a0-a6
	rts


print_caractere_pas_retourdebutligneaudessus:

	lea		ecran1,a1
	moveq	#0,d1
	move.w	curseur_x,d1
	add.l	d1,a1
	moveq	#0,d1
	move.w	curseur_y,d1
	mulu	#nb_octets_par_ligne,d1
	add.l	d1,a1

	lsl.l	#3,d0		; * 8
	lea		fonte,a0
	add.l	d0,a0
	
	
; copie 1 lettre
	move.l	#8-1,d0
copieC_ligne:
	moveq	#8-1,d1
	move.b	(a0)+,d2
copieC_colonne:
	moveq	#0,d4
	btst	d1,d2
	beq.s	pixel_a_zero
	moveq	#0,d4
	move.w	couleur_char,d4
pixel_a_zero:
	move.b	d4,(a1)+
	dbf		d1,copieC_colonne
	lea		nb_octets_par_ligne-8(a1),a1
	dbf		d0,copieC_ligne

	move.w	curseur_x,d0
	add.w	#8,d0
	cmp.w	#320,d0
	blt		curseur_pas_fin_de_ligne
	moveq	#0,d0
	add.w	#8,curseur_y
curseur_pas_fin_de_ligne:
	move.w	d0,curseur_x

	movem.l (a7)+,d0-d7/a0-a6

	rts


;----------------------------------
; recopie l'object list dans la courante

copy_olist:
				move.l	#ob_list_courante,A1_BASE			; = DEST
				move.l	#$0,A1_PIXEL
				move.l	#PIXEL16|XADDPHR|PITCH1,A1_FLAGS
				move.l	#ob_liste_originale,A2_BASE			; = source
				move.l	#$0,A2_PIXEL
				move.l	#PIXEL16|XADDPHR|PITCH1,A2_FLAGS
				move.w	#1,d0
				swap	d0
				move.l	#fin_ob_liste_originale-ob_liste_originale,d1
				move.w	d1,d0
				move.l	d0,B_COUNT
				move.l	#LFU_REPLACE|SRCEN,B_CMD
				rts


	.if			1=0
; ---------------------------------------
; allocation de mémoire
; malloc de d0, retour avec  un pointeur dans d0
; ---------------------------------------

YM_malloc:

	movem.l		d1-d3/a0,-(sp)

	move.l		debut_ram_libre,d1
	move.l		d1,a0
	move.l		d1,d3
; arrondit multiple de 2
    btst		#0,d0
	beq.s		YM_malloc_pas_d_arrondi
	addq.l		#1,d0
YM_malloc_pas_d_arrondi:
	add.l		d0,d1
	move.l		d1,debut_ram_libre
	
	move.l		d0,d2
	subq.l		#1,d2
	moveq.l		#0,d0

YM_malloc_boucle_clean_ram:
	move.b		d0,(a0)+
	dbf			d2,YM_malloc_boucle_clean_ram
	
	move.l		d3,d0

	movem.l		(sp)+,d1-d3/a0
	rts

; ---------------------------------------
; allocation de mémoire version RAM DSP
; malloc de d0, retour avec  un pointeur dans d0
; d0 => forcément un multiple de 4
; ---------------------------------------

YM_malloc_DSP:

	movem.l		d1-d3/a0,-(sp)

	move.l		debut_ram_libre_DSP,d1
	move.l		d1,a0
	move.l		d1,d3
	add.l		d0,d1
	move.l		d1,debut_ram_libre_DSP
	
	move.l		d0,d2
	moveq.l		#0,d0
	lsr.l		#2,d2		; 4 octets par 4 octets
	subq.l		#1,d2

YM_malloc_boucle_clean_ram_DSP:
	move.l		d0,(a0)+
	dbf			d2,YM_malloc_boucle_clean_ram_DSP
	
	move.l		d3,d0

	movem.l		(sp)+,d1-d3/a0
	rts


	.endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Procedure: InitVideo (same as in vidinit.s)
;;            Build values for hdb, hde, vdb, and vde and store them.
;;

InitVideo:
                movem.l d0-d6,-(sp)

				
				move.w	#-1,ntsc_flag
				move.l	#50,_50ou60hertz
	
				move.w  CONFIG,d0                ; Also is joystick register
                andi.w  #VIDTYPE,d0              ; 0 = PAL, 1 = NTSC
                beq     .palvals
				move.w	#1,ntsc_flag
				move.l	#60,_50ou60hertz
	

.ntscvals:		move.w  #NTSC_HMID,d2
                move.w  #NTSC_WIDTH,d0

                move.w  #NTSC_VMID,d6
                move.w  #NTSC_HEIGHT,d4
				
                bra     calc_vals
.palvals:
				move.w #PAL_HMID,d2
				move.w #PAL_WIDTH,d0

				move.w #PAL_VMID,d6				
				move.w #PAL_HEIGHT,d4

				
calc_vals:		
                move.w  d0,width
                move.w  d4,height
                move.w  d0,d1
                asr     #1,d1                   ; Width/2
                sub.w   d1,d2                   ; Mid - Width/2
                add.w   #4,d2                   ; (Mid - Width/2)+4
                sub.w   #1,d1                   ; Width/2 - 1
                ori.w   #$400,d1                ; (Width/2 - 1)|$400
                move.w  d1,a_hde
                move.w  d1,HDE
                move.w  d2,a_hdb
                move.w  d2,HDB1
                move.w  d2,HDB2
                move.w  d6,d5
                sub.w   d4,d5
                add.w   #16,d5
                move.w  d5,a_vdb
                add.w   d4,d6
                move.w  d6,a_vde
			
			    move.w  a_vdb,VDB
				move.w  a_vde,VDE    
				
				
				move.l  #0,BORD1                ; Black border
                move.w  #0,BG                   ; Init line buffer to black
                movem.l (sp)+,d0-d6
                rts

; - routines de debug
;
bus_error_68000:
	;.if			GD_DEBUG=1
	;lea			debug_USB_GD__bus_error,a0
	;jsr			fonction_GD_DebugString
	;.endif
	moveq		#0,d0
bus_error_68000_2:
	move.w	d0,BG						
	move.w	d0,BORD1
	addq.w	#1,d0
	bra.s	bus_error_68000_2

address_error_68000:
	;.if			GD_DEBUG=1
	;lea			debug_USB_GD__address_error,a0
	;jsr			fonction_GD_DebugString
	;.endif
	moveq		#0,d0
address_error_68000_2:
	move.w	d0,BG						
	addq.w	#1,d0
	bra.s	address_error_68000_2



	.dphrase
	.include	"WODTFMX.S"

	.68000
	.dphrase
	.text

	.phrase
	.include	"../Paula_v2_1_include_WoD.s"
	
	.68000
	.text
	
	.rept				7
	dc.l				0
	.endr
	
	.data
	
	
	.dphrase
Paula_custom:
channela:	; $dff0a0
; total = 4+2+2+8 = 16
		dc.l		silence			; adresse debut sample .L														00
		dc.w		4				; taille en words du sample .W												04
		dc.w		0				; period/note du canal																06
		dc.w		0				; volume .W 																					08
		dc.w		0				; length interne																			10
		dc.l		silence		; location interne																		12
channelb:
		dc.l		silence			; adresse debut sample .L														16
		dc.w		4				; taille en words du sample .W												20
		dc.w		0				; period/note du canal																22
		dc.w		0				; volume .W 																					24
		dc.w		0				; length interne																			26
		dc.l		silence		; location interne																		28
channelc:
		dc.l		silence			; adresse debut sample .L														32
		dc.w		4				; taille en words du sample .W												36
		dc.w		0				; period/note du canal																38
		dc.w		0				; volume .W 																					40
		dc.w		0				; length interne																			42
		dc.l		silence		; location interne																		44
channeld:
		dc.l		silence			; adresse debut sample .L														48
		dc.w		4				; taille en words du sample .W												52
		dc.w		0				; period/note du canal																54
		dc.w		0				; volume .W 																					56
		dc.w		0				; length interne																			58
		dc.l		silence		; location interne																		60


	.phrase
taille_une_entree_buffer_asynchrone = 16	
table_buffers_paula_asynchrones:
		dc.l				buffers_paula_asynchrones
		dc.l				buffers_paula_asynchrones+(taille_une_entree_buffer_asynchrone*4*1)				; multiple de 4
		dc.l				buffers_paula_asynchrones+(taille_une_entree_buffer_asynchrone*4*2)
		dc.l				buffers_paula_asynchrones+(taille_une_entree_buffer_asynchrone*4*3)
		dc.l				buffers_paula_asynchrones+(taille_une_entree_buffer_asynchrone*4*4)
		dc.l				buffers_paula_asynchrones+(taille_une_entree_buffer_asynchrone*4*5)
		dc.l				buffers_paula_asynchrones+(taille_une_entree_buffer_asynchrone*4*6)
		dc.l				buffers_paula_asynchrones+(taille_une_entree_buffer_asynchrone*4*7)

table_buffers_paula_asynchrones__READ:				dc.l			0
table_buffers_paula_asynchrones__WRITE:				dc.l			0

buffers_paula_asynchrones:
		ds.b				taille_une_entree_buffer_asynchrone*4*8


;		dc.l	sample_reference
;		dc.w	(fin_sample_reference-sample_reference)/2
;		dc.w		110
;		dc.w		63
;		ds.b		6		; Custom chip canal 0
		
chaine_HIPPEL:						dc.b	"TFMX player for Jaguar  V2.2 asynchronous",10,0
chaine_Hz_init_LSP:				dc.b	" Hz.",10,0
chaine_replay_frequency:		dc.b	"Replay frequency : ",0
chaine_frequency_correction:	dc.b	"Frequency correction : ",0
chaine_replay_songnumber:		dc.b	"songnumber: ",0
chaine_replay_volumes:			dc.b	"volumes music/SFX : ",0
		.phrase
;sample_reference:
;		.incbin			"C:/Jaguar/bruitages/utilises/bossgalaga_hatch.raw"
;fin_sample_reference:

        .68000
		.dphrase
ob_liste_originale:           				 ; This is the label you will use to address this in 68K code
        .objproc 							   ; Engage the OP assembler
		.dphrase

        .org    ob_list_courante			 ; Tell the OP assembler where the list will execute
;
        branch      VC < 0, .stahp    			 ; Branch to the STOP object if VC < 0
        branch      VC > 265, .stahp   			 ; Branch to the STOP object if VC > 241
			; bitmap data addr, xloc, yloc, dwidth, iwidth, iheight, bpp, pallete idx, flags, firstpix, pitch
        bitmap      ecran1, 16, 26, nb_octets_par_ligne/8, nb_octets_par_ligne/8, 246-26,3
		;bitmap		ecran1,16,24,40,40,255,3
        jump        .haha
.stahp:
        stop
.haha:
        jump        .stahp
		
		.68000
		.dphrase
fin_ob_liste_originale:


			.data
	.dphrase

stoplist:		dc.l	0,4

fonte:	
	.include	"../fonte1plan.s"
	even

couleur_char:				dc.w		25
curseur_x:					dc.w		0
curseur_y:					dc.w		curseur_Y_min
		even

			
		.dphrase

speech:
	.incbin		"../SPEECH.SEQ"
	.phrase



	.phrase
	.data

DEBUT_BSS:
_50ou60hertz:			ds.l	1
ntsc_flag:				ds.w	1
a_hdb:          		ds.w   1
a_hde:          		ds.w   1
a_vdb:          		ds.w   1
a_vde:          		ds.w   1
width:          		ds.w   1
height:         		ds.w   1
taille_liste_OP:		ds.l	1
vbl_counter:			ds.l	1

            .dphrase
ecran1:				ds.w		320*256				; 8 bitplanes
FIN_RAM:
