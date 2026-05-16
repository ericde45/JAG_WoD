; version WoD
; 2 voies YM + 1 voie DG + 2 voies SFX => 5 voies... => 15,5 bits pour 5 voies : volume différent pour les SFX => 15 bits par SFX + SAT16S
;------------------------------------------------------------------------------------

; After initialisation the DACs should be written to
; with values decreasing from 8000 to zero at sample rate. This will
; avoid a loud click on start up.












;------------------------------------------------------------------------------------
;---------
;OK -shutdown clean : a tester : OK
; 	R17 = routine I2S
;			I2S : OK
;			timer1 : OK
;			timer 2 : OK
;			main central : OK

; OK - ajouter timer 2 / PAD

;---------
; OK - gerer buffer pour 50 Hz en 60 Hz
;		0 1 2 3 4 5 6 7 8 9 10 11 12 13 .B = 14 octets => 16 octets
;		+
;		- debut sample DG .L		+4
;		- fin_sample_DG .L			+4 
;		= 24

;---------
; OK - 2 voies SFX
;		OK : - 1 registre ALT permanent pour l'increment
;		- 
;---------
; OK - DSP_volume_SFX + DSP_volume_music




; timer I2S = generation des samples
; Timer 1 = routine de replay

; DG : 6258 Hz / mono
; frequence fixe => increment toujours identique...


;CC (Carry Clear) = %00100
;CS (Carry Set)   = %01000
;EQ (Equal)       = %00010
;MI (Minus)       = %11000
;NE (Not Equal)   = %00001
;PL (Plus)        = %10100
;HI (Higher)      = %00101
;T (True)         = %00000

song_number=1

volume_music=256				; 0-256
volume_SFX=256					; 0-256

YM_correction_frequence=27

; DSP_flag_STOP
; 0-1 = running
DSP_STOP_flag_STOP_NOW=2
DSP_STOP_flag_arret_I2S=3
DSP_STOP_flag_arret_Timer1=4
DSP_STOP_flag_arret_Timer2=5
DSP_STOP_flag_arret_main=6


flag_replay_madmax=1




	include	"jaguar.inc"

; STEREO
STEREO									.equ			1			; 0=mono / 1=stereo
STEREO_shit_bits						.equ			4
; stereo weights : 0 to 16
YM_DSP_Voie_A_pourcentage_Gauche		.equ			14
YM_DSP_Voie_A_pourcentage_Droite		.equ			2
YM_DSP_Voie_B_pourcentage_Gauche		.equ			10
YM_DSP_Voie_B_pourcentage_Droite		.equ			6
YM_DSP_Voie_C_pourcentage_Gauche		.equ			6
YM_DSP_Voie_C_pourcentage_Droite		.equ			10
YM_DSP_Voie_D_pourcentage_Gauche		.equ			2
YM_DSP_Voie_D_pourcentage_Droite		.equ			14
; SFX stereo weights
YM_DSP_SFX_G_pourcentage_Gauche		.equ			4
YM_DSP_SFX_G_pourcentage_Droite		.equ			12
YM_DSP_SFX_D_pourcentage_Gauche		.equ			12
YM_DSP_SFX_D_pourcentage_Droite		.equ			4



nb_bits_virgule_offset					.equ			11					; 11 ok DRAM/ 8 avec samples en ram DSP
volume_digidrums=128

; algo de la routine qui genere les samples
; 3 canaux : increment onde carrée * 3 , increment noise, volume voie * 3 , increment enveloppe

CLEAR_BSS			.equ			1									; 1=efface toute la BSS jusqu'a la fin de la ram centrale
DSP_random_Noise_generator_method	.equ		4						; algo to generate noise random number : 1 & 4 (LFSR) OK uniquement // 2 & 3 : KO
display_infos_during_replay			.equ		1
display_infos_debug					.equ		1
VBLCOUNTER_ON_DSP_TIMER1			.equ		0						; 0=vbl counter in VI interrupt CPU / 1=vbl counter in Timer 1

	
DSP_Audio_frequence					.equ			22600				; real hardware needs lower sample frequencies than emulators !
YM_frequence_YM2149					.equ			2000000				; 2 000 000 = Atari ST , 1 000 000 Hz = Amstrad CPC, 1 773 400 Hz = ZX spectrum 
YM_DSP_frequence_MFP				.equ			2457600
YM_DSP_precision_virgule_digidrums	.equ			11
YM_DSP_precision_virgule_SID		.equ			16
YM_DSP_precision_virgule_envbuzzer	.equ			16

;YM_frequence_predivise				.equ			394339				; ((YM_frequence_YM2149/16)*65536)/DSP_Audio_frequence

; 21500 => 21867
; 23000 => 23082
; 25000 => 23082
; 27000 => 27698
; 32000 => 34623
; 35000 => 37771

; 7	51935,54688 Hz
; 8	46164,93056 Hz
; 9	41548,4375  Hz
; 12	31960,33654
; 15	25967,77344
; 19	20774,21875
; 51	7990,084135


; Timer 1 du DSP
; 26.593900 / prediviser +1 / seconde diviseur +1 .
; pour 50 hz : 26593900 hz => 531 878 => 2 × 73 × 3643 => prediviseur = 146 / 3643

; ----------------------------
; parametres affichage
;ob_liste_originale			equ		(ENDRAM-$4000)							; address of list (shadow)
ob_list_courante			equ		((ENDRAM-$4000)+$2000)				; address of read list
nb_octets_par_ligne			equ		320
nb_lignes					equ		256


DSP_STACK_SIZE	equ	32	; long words
DSP_USP			equ		(D_ENDRAM-(4*DSP_STACK_SIZE))
DSP_ISP			equ		(DSP_USP-(4*DSP_STACK_SIZE))

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

	;bsr			anti_click_startup

; init curseur / relaunch test
	move.w		#25,couleur_char
	move.w		#0,curseur_x
	move.w		#curseur_Y_min,curseur_y
; init dsp volumes for relaunch test
	move.l		#volume_SFX,DSP_volume_SFX
	move.l		#volume_music,DSP_volume_music


;.noclear
; clear BSS

	.if			CLEAR_BSS=1
	lea			DEBUT_BSS,a0
	lea			FIN_RAM,a1
	moveq		#0,d0
	
boucle_clean_BSS:
	move.b		d0,(a0)+
	cmp.l		a0,a1
	bne.s		boucle_clean_BSS
	.endif
	
		
	move.w		#$000,JOYSTICK


;check ntsc ou pal:

	moveq		#0,d0
	move.w		JOYBUTS ,d0

	move.l		#26593900,frequence_Video_Clock			; PAL
	move.l		#415530,frequence_Video_Clock_divisee

	
	btst		#4,d0
	beq.s		jesuisenpal
jesuisenntsc:
	move.l		#26590906,frequence_Video_Clock			; NTSC
	move.l		#415483,frequence_Video_Clock_divisee
jesuisenpal:





	move.l		#INITSTACK, sp	
	move.w		#%0000011011000111, VMODE			; 320x256
	move.w		#$100,JOYSTICK
    bsr     InitVideo               	; Setup our video registers.


	;bsr		creer_Object_list
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
	

	move.l	#ob_list_courante,d0					; set the object list pointer
	swap	d0
	move.l	d0,OLP


; launche music
	moveq		#song_number,d0
	jsr			music


	move.l  #VBL,LEVEL0     	; Install 68K LEVEL0 handler
	move.w  a_vde,d0                	; Must be ODD
	;sub.w   #16,d0
	ori.w   #1,d0
	move.w  d0,VI

	move.w  #%01,INT1                 	; Enable video interrupts 11101


	and.w   #%1111100011111111,sr				; 1111100011111111 => bits 8/9/10 = 0
	and.w   #$f8ff,sr



; ------------------------
; debut DSP
	move.l	#0,D_CTRL

; copie du code DSP dans la RAM DSP

	lea		YM_DSP_debut,A0
	lea		D_RAM,A1
	move.l	#YM_DSP_fin-DSP_base_memoire,d0
	lsr.l	#2,d0
	


	sub.l	#1,D0
boucle_copie_bloc_DSP:
	move.l	(A0)+,(A1)+
	dbf		D0,boucle_copie_bloc_DSP

; CLS
	;moveq	#0,d0
	;bsr		print_caractere
	

; init DSP
	move.l		#50,YM_frequence_replay
	move.l		#silence,d0
	move.l		#silence+2,d1
	lsl.l			#8,d0
	lsl.l			#8,d1
	lsl.l			#nb_bits_virgule_offset-8,d0
	lsl.l			#nb_bits_virgule_offset-8,d1
	move.l		d0,DSP_pointeur_adresse_dg_a_virgule
	move.l		d1,DSP_pointeur_adresse_de_fin_dg_a_virgule

	
	
	
	; set timers
	move.l		#DSP_Audio_frequence,d0
	move.l		frequence_Video_Clock_divisee,d1
	lsl.l		#8,d1
	divu		d0,d1
	and.l		#$ffff,d1
	add.l		#128,d1			; +0.5 pour arrondir
	lsr.l		#8,d1
	subq.l		#1,d1
	move.l		d1,DSP_parametre_de_frequence_I2S

;calcul inverse
 	addq.l	#1,d1
	add.l	d1,d1		; * 2 
	add.l	d1,d1		; * 2 
	lsl.l	#4,d1		; * 16
	move.l	frequence_Video_Clock,d0
	divu	d1,d0			; 26593900 / ( (16*2*2*(+1))
	and.l		#$ffff,d0
	add.l		#YM_correction_frequence,d0
	move.l	d0,DSP_frequence_de_replay_reelle_I2S

	;bsr			YM_calcul_frequences_Sinus_Sid


	bsr				Hippel_replay_asynchronous
	bsr				Hippel_replay_asynchronous


; launch DSP

	move.l	#0,vbl_counter_replay_DSP
	move.l	#REGPAGE,D_FLAGS
	move.l	#DSP_routine_init_DSP,D_PC
	move.l	#DSPGO,D_CTRL
	move.l	#0,vbl_counter

; calcul RAM DSP
	move.l		#D_ENDRAM,d0
	sub.l		debut_ram_libre_DSP,d0
	
	move.l		a0,-(sp)
	lea			chaine_RAM_DSP,a0
	bsr			print_string
	move.l		(sp)+,a0
	
	bsr			print_nombre_4_chiffres
; ligne suivante
	moveq		#10,d0
	bsr			print_caractere

	move.b		#85,couleur_char

; replay frequency
	move.l		a0,-(sp)
	lea			chaine_replay_frequency,a0
	bsr			print_string
	move.l		(sp)+,a0

	move.l		DSP_frequence_de_replay_reelle_I2S,d0
	bsr			print_nombre_5_chiffres

	move.l		a0,-(sp)
	lea			chaine_HZ_init_YM7,a0
	bsr			print_string
	move.l		(sp)+,a0

	

	move.b		#145,couleur_char
	
	move.l		a0,-(sp)
	lea			chaine_playing_YM7,a0
	bsr			print_string
	move.l		(sp)+,a0

	move.l		#STEREO,d1
	cmp.l		#1,d1
	beq.s		printstereo

	lea			chaine_playing_YM7_MONO,a0
	bsr			print_string

	bra.s		okprintms
printstereo:
	lea			chaine_playing_YM7_STEREO,a0
	bsr			print_string
okprintms:

	move.b		#245,couleur_char



main:	
	.if				1=0
; attente timer 1
	move.l			flag_timer1,d0
	cmp.l			#0,d0
	beq.s			main
	move.l			#0,flag_timer1
	.endif
	
	;bsr				Hippel_replay_asynchronous
	
	
	
	
	
; test arret + redémarrage
; test keys / pad
; xxxxxxCx xxBx2580 147*oxAP 369#RLDU
				move.l		DSP_pad1,d0
				
; test	
				;cmp.l		#$FCC00000,d0
				;beq.s		.okok
				;nop
				;nop
;.okok:				
				
				move.l		d0,d1
				and.l			#U235SE_BUT_A,d1
				beq			pas_button_A
				; button A = restart all

				; stop VBL
				move.l			#VBL_empty,LEVEL0
				; volumes = 0
				bsr				fade_out_YM
				
				; stop DSP
				move.l			#DSP_STOP_flag_STOP_NOW,DSP_flag_STOP
				
				; wait for DSP to fully stop
.2:
					move.l  	D_CTRL,d0               ; Wait for complete
					andi.l  		#$1,d0
					bne.s   		.2

; eviter le clic/noise ?
					nop
					nop
					;bsr				anti_click_shutdown
					move.l			#0,L_I2S
					move.l			#0,L_I2S+4
					
				; stop  music
				moveq		#0,d0
				jsr			music

				jmp			relaunch_all


				
pas_button_A:
				move.l		d0,d1
				and.l			#U235SE_BUT_B,d1
				beq.s		.pas_button_B
				move.l		d0,-(sp)
				moveq		#3,d0			; sample=1
				moveq		#1,d1			; right
				bsr		plays_speech_sfx
				move.l		(sp)+,d0
.pas_button_B:
				move.l		d0,d1
				and.l			#U235SE_BUT_C,d1
				beq.s		.pas_button_C
				move.l		d0,-(sp)
				moveq		#4,d0			; sample=2
				moveq		#0,d1			; left
				bsr			plays_speech_sfx
				move.l		(sp)+,d0
.pas_button_C:
	




	.if		display_infos_during_replay=1


; gestion affichage ligne indicateurs
;envA
	move.b		#" ",d0
	move.l		#YM_DSP_volE,d1
	cmp.l		YM_DSP_pointeur_sur_source_du_volume_A,d1
	bne.s		.envA
	move.b		#"E",d0
.envA:
	move.b		d0,chaine_replay_envA
;envB
	move.b		#" ",d0
	move.l		#YM_DSP_volE,d1
	cmp.l		YM_DSP_pointeur_sur_source_du_volume_B,d1
	bne.s		.envB
	move.b		#"E",d0
.envB:
	move.b		d0,chaine_replay_envB
;envC
	move.b		#" ",d0
	move.l		#YM_DSP_volE,d1
	cmp.l		YM_DSP_pointeur_sur_source_du_volume_C,d1
	bne.s		.envC
	move.b		#"E",d0
.envC:
	move.b		d0,chaine_replay_envC
;TA
	move.b		#"T",d0
	cmp.l		#0,	YM_DSP_Mixer_TA
	beq.s		.TA
	move.b		#" ",d0
.TA:
	move.b		d0,chaine_replay_TA
;NA
	move.b		#"N",d0
	cmp.l		#0,	YM_DSP_Mixer_NA
	beq.s		.NA
	move.b		#" ",d0
.NA:
	move.b		d0,chaine_replay_NA

;TB
	move.b		#"T",d0
	cmp.l		#0,	YM_DSP_Mixer_TB
	beq.s		.TB
	move.b		#" ",d0
.TB:
	move.b		d0,chaine_replay_TB
;NB
	move.b		#"N",d0
	cmp.l		#0,	YM_DSP_Mixer_NB
	beq.s		.NB
	move.b		#" ",d0
.NB:
	move.b		d0,chaine_replay_NB

;TC
	move.b		#"T",d0
	cmp.l		#0,	YM_DSP_Mixer_TC
	beq.s		.TC
	move.b		#" ",d0
.TC:
	move.b		d0,chaine_replay_TC
;NC
	move.b		#"N",d0
	cmp.l		#0,	YM_DSP_Mixer_NC
	beq.s		.NC
	move.b		#" ",d0
.NC:
	move.b		d0,chaine_replay_NC






	lea			chaine_replay_YM7,a0
	bsr			print_string
	


; compteur de temps

	.if			VBLCOUNTER_ON_DSP_TIMER1=1
	move.l		vbl_counter_replay_DSP,d0
	.endif
	.if			VBLCOUNTER_ON_DSP_TIMER1=0
	move.l		vbl_counter,d0
	.endif
	move.l		d0,d1
	move.l		_50ou60hertz,d2
	divu		d2,d1
	and.l		#$FFFF,d1			; d1=secondes

	move.l		d1,d0
	divu		#60,d0
	and.l		#$FFFF,d0
	move.l		d0,d2
	bsr			print_nombre_2_chiffres

; ":"
	moveq	#0,d0
	move.b	#":",d0
	bsr		print_caractere

	mulu		#60,d2
	sub.l		d2,d1
	move.l		d1,d0
	bsr			print_nombre_2_chiffres_force

	moveq	#0,d0
	move.b	#" ",d0
	bsr		print_caractere

	
; retour a la ligne	
	moveq	#10,d0
	bsr		print_caractere

	.endif

	.if		display_infos_debug=1
	
	move.l	YM_DSP_registre8,d0
	bsr		print_nombre_2_chiffres_force
	
	move.l	#' ',d0
	bsr		print_caractere

	move.l	YM_DSP_volA,d0
	bsr		print_nombre_hexa_6_chiffres
	
	move.l	#' ',d0
	bsr		print_caractere

	move.l	YM_DSP_volB,d0
	bsr		print_nombre_hexa_6_chiffres

	move.l	#' ',d0
	bsr		print_caractere

	move.l	YM_DSP_volC,d0
	bsr		print_nombre_hexa_6_chiffres

	move.l	#' ',d0
	bsr		print_caractere

	;move.l	YM_DSP_taille_sample_SID_voie_A,d0
	;bsr		print_nombre_hexa_6_chiffres

	;move.l	#' ',d0
	;bsr		print_caractere

	;move.l	YM_DSP_volA,d0
	;bsr		print_nombre_hexa_4_chiffres


	

; ligne suivant
	moveq	#10,d0
	bsr		print_caractere
	
	moveq	#8,d0
	bsr		print_caractere
	moveq	#8,d0
	bsr		print_caractere
	
	
	.endif

	
	bra			main

click_duree=15
temps_boucle_fadeout=20

; fade out volumes
fade_out_YM:
					move.l		DSP_volume_music,d0
					move.l		DSP_volume_SFX,d1
					
fade_out_YM_main_loop:
					cmp.l		#0,d0
					beq.s		.1
					subq.l		#1,d0
.1:					
					cmp.l		#0,d1
					beq.s		.2
					subq.l		#1,d1
.2:
					move.l		d0,DSP_volume_music
					move.l		d1,DSP_volume_SFX

					move.w		#temps_boucle_fadeout,d7
wait_fadeout:					
					nop
					dbf			d7,wait_fadeout


					cmp.l		#0,d0
					bne.s		fade_out_YM_main_loop
					cmp.l		#0,d1
					bne.s		fade_out_YM_main_loop

					move.w		#temps_boucle_fadeout,d7
wait_fadeout2:					
					nop
					dbf			d7,wait_fadeout2


					rts
					



; eviter le clic/noise ?
anti_click_startup:
					move.l		#$FFFFF800,d2
					move.l		#0,d0
					lea			L_I2S,a0
decrease_clicks:					
					move.l		d0,(a0)
					move.w		#click_duree,d1
wait_clicks:
					nop
					dbf			d1,wait_clicks
					subq.l		#1,d0
					cmp.l		d0,d2
					bne.s		decrease_clicks

					move.l		#$FFFFC800,d2
					move.l		#0,d0
					lea			L_I2S+4,a0
decrease_clicks2:					
					move.l		d0,(a0)
					move.w		#click_duree,d1
wait_clicks2:
					nop
					dbf			d1,wait_clicks2
					subq.l		#1,d0
					cmp.l		d0,d2
					bne.s		decrease_clicks2
					rts


anti_click_shutdown:
					move.l		#$FFFFF800,d0
					lea			L_I2S,a0
decrease_click:					
					move.l		d0,(a0)
					move.w		#click_duree,d1
wait_click:
					nop
					dbf			d1,wait_click
					addq.l		#1,d0
					cmp.l		#0,d0
					bne.s		decrease_click

					move.l		#$FFFFC800,d0
					lea			L_I2S+4,a0
decrease_click2:					
					move.l		d0,(a0)
					move.w		#click_duree,d1
wait_click2:
					nop
					dbf			d1,wait_click2
					addq.l		#1,d0
					cmp.l		#0,d0
					bne.s		decrease_click2
					rts


plays_speech_sfx:
; d0=sample number
; d1=sfx channel ( 0=left / 1=right)
; speech+8 +(numéro*24) : offset debug, taille
; volume = 63 / period = $240
			lea			speech+8,a0
			mulu			#24,d0
			lea			(a0,d0.w),a0
			move.l		(a0),d3
			move.l		4(a0),d4
			and.w		#$FFFE,d3
			and.w		#$FFFE,d4
			lea			PAULA_SFX_left,a1
			lea			PAULA_SFX_left_private,a3
			cmp.w		#1,d1
			bne.s		.left
			lea			PAULA_SFX_right,a1
			lea			PAULA_SFX_right_private,a3
.left:
			move.l		4(a3),d6			; fin
			move.l		#silence+2,d7
			lsl.l			#8,d7
			lsl.l			#nb_bits_virgule_offset-8,d7
			cmp.w		d7,d6
			bne.s		.exit
			move.l		#63,d5
			lea			speech+8+(24*14),a2
			add.l			a2,d3
			lsl.l			#8,d3
			lsl.l			#nb_bits_virgule_offset-8,d3		; location << nb_bits_virgule_offset
			add.l			a2,d4
			lsl.l			#8,d4
			lsl.l			#nb_bits_virgule_offset-8,d4		; end << nb_bits_virgule_offset

			movem.l	d3-d5,(a1)				; debut, fin, volume
.exit:			
			rts

;PAULA_SFX_left:
;	dc.l			silence<<nb_bits_virgule_offset								;  0 : interne
;	dc.l			(silence+2)<<nb_bits_virgule_offset						;  2 : interne
;	dc.l			0																				;  3 : volume




Hippel_replay_asynchronous:
				move.l		table_buffers_paula_asynchrones__WRITE,d0
				move.l		table_buffers_paula_asynchrones__READ,d1
				sub.w		d1,d0				; WRITE - READ
				and.w		#%111,d0			; loop sur 8
				cmp.w		#3,d0
				bgt.s			Hippel_replay_asynchronous_main_no_play
				
				.if				flag_replay_madmax=1
				jsr				music+4
				bsr			copie_YM_to_data_stack
				.endif
				;move.l		#flag_prise_en_compte_valeurs_PAULA,Paula_flag_Tick_50Hz
				addq.w		#1,compteur_frame_music
Hippel_replay_asynchronous_main_no_play:				
				rts
compteur_frame_music:			dc.w				0



copie_YM_to_data_stack:
		move.l				table_buffers_paula_asynchrones__WRITE,d0
		move.l				d0,d1
		lsl.w					#2,d0			; *4
		lea					table_buffers_paula_asynchrones,a0
		move.l				(a0,d0.w),a2
		lea					ym2149+2,a1
; copie YM .B
		move.b				(a1),(a2)+					; YM reg 0
		move.b				(4*1)(a1),(a2)+			; YM reg 1
		move.b				(4*2)(a1),(a2)+
		move.b				(4*3)(a1),(a2)+
		move.b				(4*4)(a1),(a2)+
		move.b				(4*5)(a1),(a2)+
		move.b				(4*6)(a1),(a2)+
		move.b				(4*7)(a1),(a2)+
		move.b				(4*8)(a1),(a2)+
		move.b				(4*9)(a1),(a2)+
		move.b				(4*10)(a1),(a2)+
		move.b				(4*11)(a1),(a2)+
		move.b				(4*12)(a1),(a2)+
		move.b				(4*13)(a1),(a2)+		; YM reg 13
		clr.b					(4*13)(a1)
		lea					2(a2),a2						; +16
;copie DG
;		move.l				DSP_debut_sample_DG,d0
;		cmp.l				#0,d0
;		beq.s				.koko
;		move.l				samplebase,d0
;		lea					nosetpor,a4
;		nop
;		nop
;
;.koko:
		move.l				DSP_debut_sample_DG,(a2)+
		move.l				DSP_fin_sample_DG,(a2)+
; avance offset adresse WRITE
		addq.w				#1,d1
		and.w				#%111,d1			; loop on 8
		move.l				d1,table_buffers_paula_asynchrones__WRITE

		rts


;--------------------------
; VBL

VBL:
                movem.l d0-d7/a0-a6,-(a7)
				
				; replay music asynchron
				bsr				Hippel_replay_asynchronous
				
				;.if		display_infos_debug=1
				;add.w		#1,BG					; debug pour voir si vivant
				;.endif

                jsr     copy_olist              	; use Blitter to update active list from shadow

                addq.l	#1,vbl_counter

                ;move.w  #$101,INT1              	; Signal we're done
                movem.l (a7)+,d0-d7/a0-a6
;.exit:
VBL_empty:
				move.w	#$101,INT1
                move.w  #$0,INT2
                rte

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
; imprime une chaine qui commence par le nb de caractere de la chaine
; a0=pointeur sur chaine “sized string”
print_string__sstring:
	movem.l d0-d7/a0-a6,-(a7)	

	moveq		#0,d0
	moveq		#0,d7
	move.b		(a0)+,d7
	subq.w		#1,d7
	
print_string__sstring__boucle:
	move.b		(a0)+,d0
	bsr			print_caractere
	dbf			d7,print_string__sstring__boucle
	movem.l 	(a7)+,d0-d7/a0-a6
	rts


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

	swap		d0
	and.l		#$F0,d0
	lsr.l		#4,d0
	and.l		#$F,d0
	and.l		#$FFFFF,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere

	move.l		d1,d0
	swap		d0
	and.l		#$F,d0
	and.l		#$FFFF,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere


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
	bsr.s		print_caractere

	move.l		d1,d0
	divu		#1000,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#1000,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr.s		print_caractere

	move.l		d1,d0
	divu		#100,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#100,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr.s		print_caractere


	move.l		d1,d0
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr.s		print_caractere
	move.l		d1,d0
	add.l		#48,d0
	bsr.s	print_caractere
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
	move.b	couleur_char,d4
pixel_a_zero:
	move.b	d4,(a1)+
	dbf		d1,copieC_colonne
	lea		nb_octets_par_ligne-8(a1),a1
	dbf		d0,copieC_ligne

	move.w	curseur_x,d0
	add.w	#8,d0
	cmp.w	#320,d0
	blt.s		curseur_pas_fin_de_ligne
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


		if		1=0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Simple Object List Routines for a simple life.
;;
;; call with *d0=object type
;;           *d1=height
;;           *d2=data width
;;           *d3=colour depth
;;           *d4=transparent
;;           *d5=image width
;;           *a0=address of object (phrase alligned)
;;           *a1=address for GFX   (phrase alligned)
;;
;; exit with object built
;;           link=object address+32
;;           scaled objects will *NOT* be 1:1 in x/y
;;           x/y positions will be -500,2 (off screen)
;;
bitmapobject    equ 0            ; object types
scaledobject    equ 1
gpuobject       equ 2
braobject       equ 3             
stopobject      equ 4

y_less          equ 0            ; branch object types
y_more          equ 1
always          equ 2

CreateObject:   lsl.w   #2,d0                   ; object type
                move.l  jmp_tab(pc,d0),a6       ; get routine address
                jmp (a6)                        ; call it!

jmp_tab:        .dc.l bitmp                     ; jump table
                .dc.l scaled
                .dc.l gpuob
                .dc.l braob
                .dc.l stopob

bitmp:          clr.l   (a0)                    ; template
                clr.l   4(a0)                   ;
                clr.l   8(a0)                   ;
                move.l  #$00008000,12(a0)       ;

                move.l  a0,d0                   ; link address
	sub.l	#ob_liste_originale,d0
	add.l	#ob_list_courante,d0

                ;sub.l   #ob_list1,d0            ;
                ;add.l   #ob_list,d0             ;
                add.l   #32,d0                  ;
                and.b   #%11111000,d0           ;
                lsl.l   #5,d0                   ;
                or.l    d0,2(a0)                ;

                move.l  a1,d0                   ; gfx address
                lsl.l   #8,d0                   ;
				

					
                or.l    d0,(a0)                 ;
				
				
				
                move.l  d1,d0                   ; height
                swap    d0                      ;
                lsr.l   #2,d0                   ;
                or.l    d0,4(a0)                ;
				
				
                ror.w   #1,d4                   ; transparency
                or.w    d4,10(a0)               ;
                lsl.w   #8,d3                   ; depth (colour depth)
                lsl.w   #4,d3                   ;
                or.w    d3,14(a0)               ;
                lsr.w   #3,d2                   ; data width
                swap    d2                      ;
                lsl.l   #2,d2                   ;
                or.l    d2,12(a0)               ;
                lsr.w   #3,d5                   ; image width
                swap    d5                      ;
                lsr.l   #4,d5                   ;
                or.l    d5,10(a0)               ;

				
                move.w  #-500,d0                ; x-pos
				
				move.w #16,d0
				
                and.w   #$fff,d0
                or.w    d0,14(a0)

                or.w    #2*8,6(a0)              ; y-pos
				
;move.w	#-32,d0	; y_pos
;and.w	#$ffff,d0
;or.w	d0,6(a0)
				
				
                lea     32(a0),a0               ; BITMAP object!
                rts

scaled:         bsr     bitmp                   ; same as bitmap
                move.l  #$0,-16(a0)             ; clear it out
                move.l  #%00000000000000000010000000100000,-12(a0)
                or.l    #$1,-28(a0)             ; SCALED object!
                rts

gpuob:          move.l  #0,(a0)+
                move.l  #$3ffa,(a0)+            ; GPU object!
                rts

				
; D1=branch type
; D2=Ypos
; A1=address if branch TAKEN
				
braob:          add     d2,d2                   ; mult y-pos
                bsr     branchobject            ; make the object
make8into32:    move.l  #braobject,d0           ;
                move.l  #always,d1              ; even it out for 32-byte
                move.l  #$7ff,d2                ; positions by following with
                lea     24(a0),a1               ; a BRA+16 object
                bsr     branchobject            ;
                lea     16(a0),a0               ;
                rts

branchobject:   clr.l   (a0)
                move.l  #3,4(a0)
                add.w   d1,d1
                move.w  branchtypes(pc,d1.w),d1
                or.w    d1,6(a0)                ; branch TYPE!
                move.l  a1,d0
	sub.l	#ob_liste_originale,d0
	add.l	#ob_list_courante,d0
                ;sub.l   #ob_list1,d0
                ;add.l   #ob_list,d0
                and.l   #$fffffff8,d0
                lsl.l   #5,d0                   ; Link if branch **TAKEN!**
                move.l  d0,2(a0)                ; (< & > swapped!)
                lsl.w   #3,d2                   ; scanline to branch on
                or.w    d2,6(a0)                ; is VC/2
                lea     8(a0),a0                ; next object
                rts

branchtypes:    .dc.w    $4000,$8000,$0000       ; 

stopob:         move.l  #0,(a0)+
                move.l  #4,(a0)+                ; STOP object!
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
                beq.s     .palvals
				move.w	#1,ntsc_flag
				move.l	#60,_50ou60hertz
	

.ntscvals:		move.w  #NTSC_HMID,d2
                move.w  #NTSC_WIDTH,d0

                move.w  #NTSC_VMID,d6
                move.w  #NTSC_HEIGHT,d4
				
                bra.s    calc_vals
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




	if		1=0
; -------------------------------------------
creer_Object_list:
; il faut créer une liste avec :
;	- un bra si y>0, sinon stop
; 	- un bra si y< max Y, sinon stop
; 	- un object bitmap
;	- un stop

; on stop tout
	move.l	#stoplist,d0
	swap.w	d0
	move.l	d0,OLP

; la creer dans ob_list_courante
; puis la copier dans ob_liste_originale


	lea		ob_liste_originale,a0

; bra pour debut ecran, y< 0
	
	move.l  a0,d0               ; address if bra not taken
	sub.l	#ob_liste_originale,d0
	add.l	#ob_list_courante,d0
    add.l   #32,d0              ; next BRA object
	lsr.l   #3,d0
	lsl.l   #8,d0
	clr.l   (a0)
	move.l  #$00008003,4(a0)    ; bra if yp<0
	or.l    d0,2(a0)            ; link to next BRA
	lea     8(a0),a0

; stop OP
	move.l  #0,(a0)+
	move.l  #4,(a0)+            ; stop object processor !
	lea     16(a0),a0			; aligner sur 32

; bra pour fin ecran Y> X
	move.l  a0,d0               ; address if bra not taken
	sub.l	#ob_liste_originale,d0
	add.l	#ob_list_courante,d0
	add.l   #32,d0
	lsr.l   #3,d0
	lsl.l   #8,d0
	clr.l   (a0)
	move.l  #$00004003,4(a0)    ; bra is yp>value
	or.l    d0,2(a0)            ; link to first object!

; test NTSC ou PAL pour ligne de fin ( en demi lignes)
	move.w	CONFIG,d6
	andi.w	#VIDTYPE,d6
	beq		.pal
	move.l	#492,d0				; NTSC = 246 lignes
	move.w	#1,ntsc_flag
	bra.s	.ntsc

.pal:
	move.l	#560,d0				; 280 lignes
	move.w	#-1,ntsc_flag

.ntsc:
	lsl.l   #3,d0
	or.l    d0,4(a0)			; la valeur Y max

	lea     8(a0),a0            ; next object
; stop OP
	move.l  #0,(a0)+
	move.l  #4,(a0)+            ; stop object processor !
	lea     16(a0),a0			; aligner sur 32



	lea		ecran1,a1
	move.l  #bitmapobject,d0        			; type
	move.l  #256,d1								; 74,d1 ; height
	move.l  #nb_octets_par_ligne,d2      						; bytes to next line
	moveq	#3,d3				; 3=8bpp, 4=16bit
	moveq	#0,d4                   			; Transparent
	;move.l  #640,d5          					; bytes/pixels*width / line;
	move.l	d2,d5
	bsr     CreateObject

	
	moveq.l #stopobject,d0          			; STOP Object
	bsr     CreateObject	
	
	

	move.l	a0,d0
	move.l	#ob_liste_originale,d1
	sub.l	d1,d0				; d0=taille de l'object list
	move.l	d0,taille_liste_OP

	rts
	endif


;----------------------------------------------------
;     routines YM
;----------------------------------------------------


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
; malloc de d0, retour avec  un pointeur dans d0, -1=pas assez de RAM dispo
; d0 => forcément un multiple de 4
; ---------------------------------------

YM_malloc_DSP:

	movem.l		d1-d3/a0,-(sp)

; arrondit d0 à 4
	addq.l		#3,d0
	and.l		#$FFFFFFFC,d0				; élimine les 2 derniers bits, multiple de 4

	move.l		debut_ram_libre_DSP,d1
	move.l		d1,d3
	add.l		d0,d3
	cmp.l		#DSP_ISP,d3
	bge.s		YM_malloc_DSP__sortie_erreur
	
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
YM_malloc_DSP__sortie_erreur:
	moveq		#-1,d0
	movem.l		(sp)+,d1-d3/a0
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











;-------------------------------------
;
;     DSP
;
;-------------------------------------

	.phrase
YM_DSP_debut:

	.dsp
	.org	D_RAM
DSP_base_memoire:

DSP_REG_IRQ_increment_6258Hz	.equr			R15
DSP_REG_IRQ_routine_I2S				.equr			R17
REG_interrupt_TMP1							.equr			R24
REG_interrupt_TMP2							.equr			R27

; CPU interrupt
	.rept	8
		nop
	.endr
; I2S interrupt
	movei	#D_FLAGS,r30											; 6 octets
	jump		(DSP_REG_IRQ_routine_I2S)													; 2 octets
	load		(r30),r29	; read flags								; 2 octets = 16 octets
		nop
		nop
		nop
; Timer 1 interrupt
	movei	#DSP_LSP_routine_interruption_Timer1,r12						; 6 octets
	movei	#D_FLAGS,r16											; 6 octets
	jump	(r12)													; 2 octets
	load	(r16),r13	; read flags								; 2 octets = 16 octets
; Timer 2 interrupt	
	movei	#DSP_LSP_routine_interruption_Timer2,r28						; 6 octets
	movei	#D_FLAGS,r30											; 6 octets
	jump	(r28)													; 2 octets
	load	(r30),r29	; read flags								; 2 octets = 16 octets
; External 0 interrupt
	.rept	8
		nop
	.endr
; External 1 interrupt
	.rept	8
		nop
	.endr













; -------------------------------
; DSP : routines en interruption
; -------------------------------
DSP_LSP_routine_interruption_I2S_STOP:
	movei		#DSP_flag_STOP,REG_interrupt_TMP2
	bclr		#5,R29		; clear I2S enabled = I2S Interrupt Enable Bit : stop I2S  => OFF
	moveq		#DSP_STOP_flag_arret_Timer1,REG_interrupt_TMP1
	store			REG_interrupt_TMP1,(REG_interrupt_TMP2)	; launch stop Timer 1

;------------------------------------	
; return from interrupt I2S
		load		(r31),r28	; return address
		bset		#10,r29		; clear latch 1 = I2S
		addq		#4,r31		; pop from stack
		bclr		#3,r29		; clear IMASK
		addqt	#2,R28		; next instruction
		jump		t,(r28)		; return
		store		R29,(r30)	; restore flags





DSP_LSP_routine_interruption_I2S:
;-------------------------------------------------------------------------------------------------
;
; routine de replay, fabrication des samples
; bank 0 : 
; R28/R29/R30/R31
; +
; R18/R19/R20/R21/R22/R23/R24/R25/R26/R27
;
;-------------------------------------------------------------------------------------------------
; R28/R29/R30/R31 : utilisé par l'interruption

; - calculer le prochain noise : 0 ou $FFFF
; - calculer le prochain volume enveloppe
; - un canal = ( mixer

;		bt = ((((yms32)posA)>>31) | mixerTA) & (bn | mixerNA);
; (onde carrée normale OU mixerTA ) ET ( noise OU mixerNA ) 

;		vol  = (*pVolA)&bt;
;		volume ( suivant le pointeur, enveloppe ou fixe) ET mask du dessus
; - increment des positions apres : position A B C, position noise, position enveloppe

; mask = (mixerTA OR Tone calculé par frequence) AND ( mixerNA OR
; avec Tone calculé = FFFFFFFF bit 31=1 : bit 31 >> 31 = 1 : NEG 1 = -1



;--------------------------
; gerer l'enveloppe
; - incrementer l'offset enveloppe
; partie entiere 16 bits : virgule 16 bits


YM_DSP_replay_sample_pas_de_Buzzer:
	movei	#YM_DSP_pointeur_enveloppe_en_cours,R24
	load	(R24),R24						; R24=pointeur sur la liste de 3 pointeur de sequence d'enveloppe : -1,0,1 : [ R24+(R25 * 4) ] + (R27*4)

YM_DSP_replay_sample_gere_env:
	movei	#YM_DSP_increment_enveloppe,R27
	movei	#YM_DSP_offset_enveloppe,R26
	load	(R27),R27				; R27 = increment enveloppe
	load	(R26),R25				; R25 = offset en cours enveloppe
	add		R27,R25					; offset+increment 16:16

	movei	#$00300000,R23
	cmp		R23,R25
	jr		mi,YM_DSP_replay_sample_offset_env_pas_de_bouclage
	nop
	movei	#$00100000,R25				; offset

YM_DSP_replay_sample_offset_env_pas_de_bouclage:
	store	R25,(R26)				; sauvegarde YM_DSP_offset_enveloppe
	shrq	#16,R25				; partie entiere uniquement
	shlq	#2,R25
	movei	#YM_DSP_volE,R26
	add		R25,R24
	load	(R24),R24				; R24 = pointeur sur la partie d'enveloppe actuelle :  [ R24+(R25 * 4) ]
	store	R24,(R26)				; volume de l'enveloppe => YM_DSP_volE

	


;--------------------------
; gérer le noise
; on avance le step de noise
; 	si on a 16 bits du haut>0 => on genere un nouveau noise
; 	et on masque le bas avec $FFFF
; l'increment de frequence du Noise est en 16:16

	movei	#YM_DSP_increment_Noise,R27
	movei	#YM_DSP_position_offset_Noise,R26
	movei	#YM_DSP_current_Noise_mask,R22
	load	(R27),R27
	load	(R26),R24
	load	(R22),R18			; R18 = current mask Noise
	add		R27,R24
	move	R24,R23
	shrq	#16,R23				; R23 = partie entiere, à zéro ?
	movei	#YM_DSP_replay_sample_pas_de_generation_nouveau_Noise,R20
	cmpq	#0,R23
	jump	eq,(R20)
	nop
; il faut generer un nouveau noise
; il faut masquer R24 avec $FFFF
	movei	#$FFFF,R23
	and		R23,R24				; YM_DSP_position_offset_Noise, juste virgule

	.if		DSP_random_Noise_generator_method=1
; generer un nouveau pseudo random methode 1
	MOVEI	#YM_DSP_current_Noise, R23		
	LOAD	(R23), R21			
	MOVEQ	#$01, R20			
	MOVE	R21, R27			
	MOVE	R21, R25			
	SHRQ	#$02, R25			
	AND		R20, R27			
	AND		R20, R25			
	XOR		R27, R25			
	MOVE	R21, R27			
	MOVE	R25, R20			
	SHRQ	#$01, R27			
	SHLQ	#$10, R20			
	OR		R27, R20			
	STORE	R20, (R23)	
	.endif

	.if		DSP_random_Noise_generator_method=2
; does not work !
; generer un nouveau pseudo random methode 2 : seed = seed * 1103515245 + 12345;
	MOVEI	#YM_DSP_Noise_seed, R23		
	LOAD	(R23), R21			
	movei	#1103515245,R20
	mult	R20,R21
	or		R21,R21
	movei	#12345,R27
	add		R27,R21
	STORE	R21, (R23)	
	.endif

	.if		DSP_random_Noise_generator_method=3
; wyhash16 : https://lemire.me/blog/2019/07/03/a-fast-16-bit-random-number-generator/
	MOVEI	#YM_DSP_Noise_seed, R23	
	movei	#$fc15,R20
	LOAD	(R23), R21
	add		R20,R21
	movei	#$2ab,R20
	mult	R20,R21
	move	R21,R25
	rorq	#16,R21
	xor		R25,R21
	store	R21,(R23)
	.endif

	.if		DSP_random_Noise_generator_method=4
; generer un nouveau pseudo random LFSR YM : https://www.smspower.org/Development/YM2413ReverseEngineeringNotes2018-05-13
	MOVEI	#YM_DSP_current_Noise, R23		
	LOAD	(R23), R21
	
	moveq	#1,R27
	move	R21,R20
	and		R27,R20				; 	bool output = state & 1;

	shrq	#1,R21				; 	state >>= 1;
	
	cmpq	#0,R20
	jr		eq,YM_DSP_replay_sample_LFSR_bit_0_egal_0
	
	nop
	movei	#$400181,R20
	xor		R20,R21
	
YM_DSP_replay_sample_LFSR_bit_0_egal_0:
	store	R21,(R23)
	.endif

; calcul masque 
	MOVEQ	#$01,R20
	and		R20,R21			; on garde juste le bit 0
	sub		R20,R21			; 0-1= -1 / 1-1=0 => mask sur 32 bits
	or		R21,R21
	store	R21,(R22)		; R21=>YM_DSP_current_Noise_mask
	move	R21,R18

YM_DSP_replay_sample_pas_de_generation_nouveau_Noise:
; en entrée : R24 = offset noise, R18 = current mask Noise

	store	R24,(R26)			; R24=>YM_DSP_position_offset_Noise


;---- ====> R18 = mask current Noise ----







;---- ====> R18 = mask current Noise ----
;--------------------------
; gérer les voies A B C 
; ---------------


; canal A

	movei	#YM_DSP_Mixer_NA,R26

	move	R18,R24				; R24 = on garde la masque du current Noise

	load	(R26),R26			; YM_DSP_Mixer_NA
	or		R26,R18				; YM_DSP_Mixer_NA OR Noise
; R18 = Noise OR mask du registre 7 de mixage du Noise A


	movei	#YM_DSP_increment_canal_A,R27
	movei	#YM_DSP_position_offset_A,R26
	load	(R27),R27
	load	(R26),R25
		
	add		R27,R25
	store	R25,(R26)							; YM_DSP_position_offset_A
	shrq	#31,R25
	neg		R25									; 0 devient 0, 1 devient -1 ($FFFFFFFF)
	
; R25 = onde carrée A

	movei	#YM_DSP_Mixer_TA,R26
	load	(R26),R26
	or		R26,R25
; R25 = onde carrée A OR mask du registre 7 de mixage Tone A


; Noise AND Tone

	movei	#YM_DSP_pointeur_sur_source_du_volume_A,R26
	and		R18,R25					; R25 = Noise and Tone

	load	(R26),R27				; R20 = pointeur sur la source de volume pour le canal A
	load	(r27),R20				; R20=volume pour le canal A 0 à 32767
	
	;movei	#pointeur_buffer_de_debug,R26
	;load	(R26),R18
	;store	R20,(R18)
	;addq	#4,R18
	;store	R18,(R26)
	;nop
	
	
	and		R25,R20					; R20=volume pour le canal A : 15 bits non signés
; R20 = sample canal A



; ---------------
; canal B
	movei	#YM_DSP_Mixer_NB,R26
	move	R24,R18				; R24 = masque du current Noise
	
	load	(R26),R26
	or		R26,R18

; R18 = Noise OR mask du registre 7 de mixage du Noise B

	movei	#YM_DSP_increment_canal_B,R27
	movei	#YM_DSP_position_offset_B,R26
	load	(R27),R27
	load	(R26),R25
	add		R27,R25
	or		R25,R25
	store	R25,(R26)							; YM_DSP_position_offset_B
	shrq	#31,R25
	neg		R25									; 0 devient 0, 1 devient -1 ($FFFFFFFF)
; R25 = onde carrée B

	movei	#YM_DSP_Mixer_TB,R26
	load	(R26),R26
	or		R26,R25
; R25 = onde carrée B OR mask du registre 7 de mixage Tone B

; Noise AND Tone

	movei	#YM_DSP_pointeur_sur_source_du_volume_B,R23
	and		R18,R25					; R25 = Noise and Tone
	load	(R23),R23				; R23 = pointeur sur la source de volume pour le canal B
	load	(r23),R23				; R23=volume pour le canal B 0 à 32767
	and		R25,R23					; R23=volume pour le canal B
; R23 = sample canal B

; ---------------
; canal C
	movei	#YM_DSP_Mixer_NC,R26
	move	R24,R18				; R24 = masque du current Noise
	
	load	(R26),R26
	or		R26,R18

; R18 = Noise OR mask du registre 7 de mixage du Noise C

	movei	#YM_DSP_increment_canal_C,R27
	movei	#YM_DSP_position_offset_C,R26
	load	(R27),R27
	load	(R26),R25
	add		R27,R25
	or		R25,R25
	store	R25,(R26)							; YM_DSP_position_offset_B
	shrq	#31,R25
	neg		R25									; 0 devient 0, 1 devient -1 ($FFFFFFFF)
; R25 = onde carrée C

	movei	#YM_DSP_Mixer_TC,R26
	load	(R26),R26
	or		R26,R25
; R25 = onde carrée B OR mask du registre 7 de mixage Tone C

; Noise AND Tone

	movei	#YM_DSP_pointeur_sur_source_du_volume_C,R22
	and		R18,R25					; R25 = Noise and Tone
	load	(R22),R22				; R23 = pointeur sur la source de volume pour le canal B
	load	(r22),R22				; R23=volume pour le canal B 0 à 32767
	and		R25,R22					; R23=volume pour le canal B
; R22 = sample canal C

; sans stereo : R20=A / R23=B / R22=C  // 15 bits non signés



;----------
; DG dans WoD : on remplace R21 par le DG 
; // sample signé 8 bits , mais YM non signé 15 bits
	movei			#DSP_pointeur_adresse_dg_a_virgule,R27
	;movei			#DSP_increment_DG_6258Hz,R24
	load				(R27),R26
	;load				(R24),R24			; increment
	move			R26,R18
	movei			#volume_digidrums,R19
	;movei			#$FF,R19
	shrq				#nb_bits_virgule_offset,R18
	loadb			(R18),R21				; de -128 a 127		= 8 bits signés // -128/+127 // chargés en load il devient non signé
	shlq				#24,R21
	add				DSP_REG_IRQ_increment_6258Hz,R26			; avance le sample
	sharq			#24,R21			; signe le sample		= 8 bits signés etendus sur 32 bits
	;and				R19,R21					; +128 => 8 bits non signés
	movei			#DSP_pointeur_adresse_de_fin_dg_a_virgule,R18
	;shlq				#5,R21				; 15 bits non signés		: 8 + 5 = 13 bits
	imult				R19,R21
	load				(R18),R19			; adresse de fin
	cmp				R19,R26			; fin ?
	jr					mi,.pas_fin_DG
	nop
	
	movei			#silence+2,R19			; nouvelle fin
	movei			#silence,R26
	shlq				#nb_bits_virgule_offset,R19
	shlq				#nb_bits_virgule_offset,R26
	store				R19,(R18)
.pas_fin_DG:	
	store				R26,(R27)


	;shrq				#2,R20
	;shrq				#2,R22
	;shrq				#2,R23			garde en 15 bits
	


; R20 = volume A non signés 13 bits non signés
; R21 = DG 13 bits non signés
; R22 = volume C non signés 13 bits non signés
; R23 = volume B non signés 13 bits non signés
; mono desactivé

;SFX
; PAULA_SFX_left
;PAULA_SFX_left:
;	dc.l			silence<<nb_bits_virgule_offset								;  0 : interne
;	dc.l			(silence+2)<<nb_bits_virgule_offset						;  2 : interne
;	dc.l			0																				;  3 : volume
;
;PAULA_SFX_right:
;	dc.l			silence<<nb_bits_virgule_offset								;  0 : interne
;	dc.l			(silence+2)<<nb_bits_virgule_offset						;  2 : interne
;	dc.l			0																				;  3 : volume


; R20/R21/R22/R23/ R27 / R28 

; SFX left = R27
	movei			#PAULA_SFX_left_private,R14
	load				(R14),R26
	move			R26,R18
;	movei			#$FF,R19
	shrq				#nb_bits_virgule_offset,R18
	loadb			(R18),R27				; de -255 a 255		= 8 bits signés // -128/+127 => loadb = non signé
	shlq				#24,R27
	add				DSP_REG_IRQ_increment_6258Hz,R26			; avance le sample
	sharq			#24,R27			; signe le sample		= 8 bits signés etendus sur 32 bits
	;and				R19,R27					; +128 => 8 bits non signés
	shlq				#7,R27				; 13 bits non signés
	
	load				(R14+1),R19			; adresse de fin
	cmp				R19,R26			; fin ?
	jr					mi,.pas_fin_SFX_left
	nop
	
	movei			#silence+2,R19			; nouvelle fin
	movei			#silence,R26
	shlq				#nb_bits_virgule_offset,R19
	shlq				#nb_bits_virgule_offset,R26
	store				R19,(R14+1)
.pas_fin_SFX_left:	
	store				R26,(R14)


; SFX right = R28
	movei			#PAULA_SFX_right_private,R14
	load				(R14),R26
	move			R26,R18
	;movei			#$FF,R19
	shrq				#nb_bits_virgule_offset,R18
	loadb			(R18),R28				; de -255 a 255		= 8 bits signés // -128/+127
	shlq				#24,R28
	add				DSP_REG_IRQ_increment_6258Hz,R26			; avance le sample
	sharq			#24,R28			; signe le sample		= 8 bits signés etendus sur 32 bits
	;and				R19,R28					; +128 => 8 bits non signés
	shlq				#7,R28				; 13 bits non signés
	load				(R14+1),R19			; adresse de fin
	cmp				R19,R26			; fin ?
	jr					mi,.pas_fin_SFX_right
	nop
	
	movei			#silence+2,R19			; nouvelle fin
	movei			#silence,R26
	shlq				#nb_bits_virgule_offset,R19
	shlq				#nb_bits_virgule_offset,R26
	store				R19,(R14+1)
.pas_fin_SFX_right:	
	store				R26,(R14)







	;.if		STEREO=0
	;shrq	#1,R20					; quand volume maxi = 32767		=> 14 bits non signés
					;;;;shrq	#1,R21					; quand volume maxi = 32767		=> 14 bits	non signés
	;shrq	#1,R23					; quand volume maxi = 32767		=> 14 bits	non signés
	;shrq	#1,R22					; quand volume maxi = 32767		=> 14 bits	non signés
	;add		R23,R20					; R20 = R20=canal A + R23=canal B				// => 15 bits non signés
				;;;;;add		R21,R20					; R20 = R20=canal A + R23=canal B + R21=canal D
	;movei	#32768,R27
	;add		R22,R20					; + canal C			=> 15,5 bits non signés
	;movei	#L_I2S,r26
	;sub		R27,R20					; resultat signé sur 16 bits 
	;movei	#L_I2S+4,r24
	;store	r20,(r26)				; write right channel
	;store	r20,(r24)				; write left channel
	;.endif

; R20 = YM A
; R23 = YM B
; R22 = YM C
; R21 = DG
; R27 = SFX left
; R28 = SFX right

; volume music
	movei		#DSP_volume_music,R26
	load			(R26),R26
	imult			R26,R20
	imult			R26,R23
	sharq			#8,R20
	imult			R26,R22
	sharq			#8,R23
	imult			R26,R21			; 21 bits non signés
	sharq			#8,R22
	sharq			#8,R21				; 13 bits non signés

; volume SFX
	movei		#DSP_volume_SFX,R26
	load			(R26),R26
	imult			R26,R27
	imult			R26,R28
	sharq			#8,R27
	sharq			#8,R28


	
	.if		STEREO=1

	movei	#YM_DSP_Voie_B_pourcentage_Droite,R24
	move	R23,R25					; R23=B
	imult	R24,R25
	sharq	#STEREO_shit_bits,R25


	movei	#YM_DSP_Voie_A_pourcentage_Droite,R24
	move	R20,R26					; R20=A = volume A non signés 15 bits
	imult	R24,R26
	sharq	#STEREO_shit_bits,R26
	
	
	movei	#YM_DSP_Voie_C_pourcentage_Droite,R24
		add		R26,R25					; R25=A+B		=> 16 bits non signés
	move	R22,R18					; R18= C non signés 15 bits ( remplace le canal C )
	imult	R24,R18
	sharq	#STEREO_shit_bits,R18


	movei	#YM_DSP_Voie_D_pourcentage_Droite,R24
		add		R18,R25																;;; 15 bits+15 bits+15bits= 16,5 bits
	move	R21,R26					; R21=DG
	imult	R24,R26
	sharq	#STEREO_shit_bits,R26
		add			R26,R25


; SFX
; 	left
	movei	#YM_DSP_SFX_G_pourcentage_Droite,R24
	move	R27,R26					; R26= sample SFX left
	imult	R24,R26
	sharq	#STEREO_shit_bits,R26
	add		R26,R25					; R27=A+B		=> 16 bits non signés
; 	right
	movei	#YM_DSP_SFX_D_pourcentage_Droite,R24
	move	R28,R26					; R26= sample SFX right
	imult		R24,R26
	sharq		#STEREO_shit_bits,R26
	add		R26,R25					; R27=A+B		=> 16 bits non signés



	movei	#YM_DSP_Voie_A_pourcentage_Gauche,R24
	imult	R24,R20
	sharq	#STEREO_shit_bits,R20
	
	movei	#YM_DSP_Voie_B_pourcentage_Gauche,R24
	imult	R24,R23
	sharq	#STEREO_shit_bits,R23
	
	movei	#YM_DSP_Voie_C_pourcentage_Gauche,R24
		add		R20,R23					; R23=A+B
	imult	R24,R22
	sharq	#STEREO_shit_bits,R22

	movei	#YM_DSP_Voie_D_pourcentage_Gauche,R24
		add		R22,R23					; A+B+C
	imult		R24,R21
	sharq		#STEREO_shit_bits,R21
		add		R21,R23					; A+B+C+DG





; SFX
; 	left
	movei	#YM_DSP_SFX_G_pourcentage_Gauche,R24
	move	R27,R26					; R26= sample SFX left
	imult	R24,R26
	sharq	#STEREO_shit_bits,R26
	add		R26,R23					; R27=A+B		=> 16 bits non signés
; 	right
	movei	#YM_DSP_SFX_D_pourcentage_Gauche,R24
	move	R28,R26					; R26= sample SFX right
	imult		R24,R26
	sharq		#STEREO_shit_bits,R26
	add		R26,R23					; R27=A+B		=> 16 bits non signés


	;movei	#YM_DSP_Voie_D_pourcentage_Gauche,R24
	;mult	R24,R21
	;shrq	#STEREO_shit_bits,R21

	;movei	#32768,R27					; signe tout ici
	

	;sub		R27,R25					; signer sur 16 bits
	movei	#L_I2S,r26
	;sub		R27,R23				 	; signer sur 16 bits
	SAT16S	R25
	movei	#L_I2S+4,r24
	SAT16S	R23

	store	r25,(r26)				; write right channel
	store	r23,(r24)				; write left channel

	.endif


;------------------------------------	
; return from interrupt I2S
	load	(r31),r28	; return address
	bset	#10,r29		; clear latch 1 = I2S
	bclr	#3,r29		; clear IMASK
	addq	#4,r31		; pop from stack
	addqt	#2,r28		; next instruction
	jump	t,(r28)		; return
	store	r29,(r30)	; restore flags




















;--------------------------------------------
; ---------------- Timer 1 ------------------
;--------------------------------------------
; autorise interruptions, pour timer I2S
DSP_LSP_routine_interruption_Timer1_STOP:

	moveq		#DSP_STOP_flag_arret_Timer2,REG_interrupt_TMP2			; launch timer 2 STOP
	bclr			#6,R13			; clear Timer 1 Interrupt Enable Bit  => OFF
	store			REG_interrupt_TMP2,(REG_interrupt_TMP1)


;------------------------------------	
; return from interrupt Timer 1
	load	(r31),r12	; return address
	bset	#11,r13		; clear latch 1 = timer 1
	bclr	#3,r13		; clear IMASK
	addq	#4,r31		; pop from stack
	addqt	#2,r12		; next instruction
	jump	t,(r12)		; return
	store	r13,(r16)	; restore flags



DSP_LSP_routine_interruption_Timer1:

; test STOP
		movei		#DSP_flag_STOP,REG_interrupt_TMP1
		load			(REG_interrupt_TMP1),REG_interrupt_TMP2
		cmpq		#DSP_STOP_flag_arret_Timer1,REG_interrupt_TMP2
		jr				eq,DSP_LSP_routine_interruption_Timer1_STOP
		nop





;-------------------------------------------------------------------------------------------------
; -------------------------------------------------------------------------------
; routine de lecture des registres YM
; bank 0 : 
 ; gestion timer deplacé sur :
; R12(R28)/R13(R29)/R16(R30)
; +
; R0/R1/R2/R3/R4/R5/R6/R7/R8/R9/R10/R11 + R14
; -------------------------------------------------------------------------------
; copie de buffers_paula_asynchrones

	movei			#table_buffers_paula_asynchrones__READ,R2
	movei			#table_buffers_paula_asynchrones,R7
	load				(R2),R3
	move			R3,R5
	moveq			#%111,R6
	addq				#1,R3
	shlq				#2,R5
	and				R6,R3				; loop on 8
	add				R5,R7
	store				R3,(R2)				; update table_buffers_paula_asynchrones__READ
	load				(R7),R1			; buffer
	





	;movei			#ym2149+2,R1
	moveq			#1,R8
;-------------------------------------------------------------------------------------------------
; round(  ((freq_YM / 16) / frequence_replay) * 65536) /x;	
; 
; registres 0+1 = frequence voie A
	loadb		(R1),R2						; registre 0
	add			R8,R1
	loadb		(R1),R3						; registre 1
	movei		#%1111,R7
	add			R8,R1


	and			R7,R3
	movei		#YM_frequence_predivise,R5
	shlq		#8,R3
	load		(R5),R5
	add			R2,R3						; R3 = frequence YM canal A

	move		R5,R6
	
	div			r3,R5
	or			R5,R5
	shlq		#16,R5
	
	movei		#YM_DSP_increment_canal_A,R2
	store		R5,(R2)


; registres 2+3 = frequence voie B
	loadb		(R1),R2						; registre 2
	add			R8,R1
	loadb		(R1),R3						; registre 3
	add			R8,R1

	and			R7,R3
	shlq		#8,R3
	move		R6,R5						; R5=YM_frequence_predivise
	add			R2,R3						; R3 = frequence YM canal B
	
	div			r3,R5
	or			R5,R5
	shlq		#16,R5
	
	movei		#YM_DSP_increment_canal_B,R2
	store		R5,(R2)
	
; registres 4+5 = frequence voie C
	loadb		(R1),R2						; registre 4
	add			R8,R1
	loadb		(R1),R3						; registre 5
	add			R8,R1

	and			R7,R3
	shlq		#8,R3
	move		R6,R5						; R5=YM_frequence_predivise
	add			R2,R3						; R3 = frequence YM canal C
	
	div			r3,R5
	or			R5,R5
	shlq		#16,R5
	
	movei		#YM_DSP_increment_canal_C,R2
	store		R5,(R2)

; registre 6
; 5 bit noise frequency
	loadb		(R1),R2						; registre 6
	movei		#%11111,R7
	add			R8,R1
	
	and			R7,R2						; on ne garde que 5 bits
	jr			ne,DSP_lecture_registre6_pas_zero
	move		R6,R5						; R5=YM_frequence_predivise

	moveq		#1,R2
DSP_lecture_registre6_pas_zero:
	
	movei		#YM_DSP_increment_Noise,R3
	div			R2,R5
	or			R5,R5
	; shlq		#15,R5						; on laisse l'increment frequence Noise sur 16(entier):16(virgule)
	store		R5,(R3)


; registre 7 
; 6 bits interessants
;	Noise	 Tone
;	C B A    C B A
	loadb		(R1),R2						; registre 7
	add			R8,R1


; bit 0 = Tone A
	move		R2,R4
	moveq		#%1,R3
	and			R3,R4					; 0 ou 1
	movei		#YM_DSP_Mixer_TA,R5
	;subq		#1,R4					; 0=>-1 / 1=>0 
	neg			R4						; 0=>0 / 1=>-1
	shlq		#1,R3					; bit suivant
	store		R4,(R5)

; bit 1 = Tone B
	move		R2,R4
	movei		#YM_DSP_Mixer_TB,R5
	and			R3,R4					; 0 ou 1
	shrq		#1,R4
	;subq		#1,R4					; 0=>-1 / 1=>0 
	neg			R4						; 0=>0 / 1=>-1
	shlq		#1,R3					; bit suivant
	store		R4,(R5)

; bit 2 = Tone C
	move		R2,R4
	movei		#YM_DSP_Mixer_TC,R5
	and			R3,R4					; 0 ou 1
	shrq		#2,R4
	;subq		#1,R4					; 0=>-1 / 1=>0 
	neg			R4						; 0=>0 / 1=>-1
	shlq		#1,R3					; bit suivant
	store		R4,(R5)
	
; bit 3 = Noise A
	move		R2,R4
	movei		#YM_DSP_Mixer_NA,R5
	and			R3,R4					; 0 ou 1
	shrq		#3,R4
	;subq		#1,R4					; 0=>-1 / 1=>0 
	neg			R4						; 0=>0 / 1=>-1
	shlq		#1,R3					; bit suivant
	store		R4,(R5)
	
; bit 4 = Noise B
	move		R2,R4
	movei		#YM_DSP_Mixer_NB,R5
	and			R3,R4					; 0 ou 1
	shrq		#4,R4
	neg			R4						; 0=>0 / 1=>-1
	;subq		#1,R4					; 0=>-1 / 1=>0 
	shlq		#1,R3					; bit suivant
	store		R4,(R5)
	
; bit 5 = Noise C
	move		R2,R4
	movei		#YM_DSP_Mixer_NC,R5
	and			R3,R4					; 0 ou 1
	shrq		#5,R4
	neg			R4						; 0=>0 / 1=>-1
;	subq		#1,R4					; 0=>-1 / 1=>0 
	shlq		#1,R3					; bit suivant
	store		R4,(R5)
	

	movei		#YM_DSP_table_de_volumes,R14

; registre 8 = volume canal A
; B4=1 bit =M / M=0=>volume fixe / M=1=>volume enveloppe
; B3/B2/B1/B0 = volume fixe pour le canal A
;	Noise	 Tone
;	C B A    C B A
	loadb		(R1),R2						; registre 8
	add			R8,R1	

	move		R2,R4
	movei		#YM_DSP_registre8,R6
	moveq		#%1111,R3
	store		R4,(R6)					; sauvegarde la valeur de volume sur 16, pour DG
	movei		#YM_DSP_volE,R5
	and			R3,R4
	
	shlq		#2,R4					; volume sur 16 *4 
	load		(R14+R4),R4

	movei		#YM_DSP_volA,R6
	store		R4,(R6)

	movei		#YM_DSP_pointeur_sur_source_du_volume_A,R3
	btst		#4,R2					; test bit M : M=0 => volume contenu dans registre 8 / M=1 => volume d'env
	jr			ne,DSP_lecture_registre8_pas_volume_A
	nop
	
	move		R6,R5
	
DSP_lecture_registre8_pas_volume_A:
	store		R5,(R3)


; registre 9 = volume canal B
; B4=1 bit =M / M=0=>volume fixe / M=1=>volume enveloppe
; B3/B2/B1/B0 = volume fixe pour le canal B
;	Noise	 Tone
;	C B A    C B A
	loadb		(R1),R2						; registre 9
	add			R8,R1	

	move		R2,R4
	movei		#YM_DSP_registre9,R6
	moveq		#%1111,R3
	store		R4,(R6)					; sauvegarde la valeur de volume sur 16, pour DG
	movei		#YM_DSP_volE,R5
	and			R3,R4

	shlq		#2,R4					; volume sur 16 *4 
	load		(R14+R4),R4

	movei		#YM_DSP_volB,R6
	store		R4,(R6)

	movei		#YM_DSP_pointeur_sur_source_du_volume_B,R3

	btst		#4,R2
	jr			ne,DSP_lecture_registre9_pas_env
	nop
	
	move		R6,R5
	
DSP_lecture_registre9_pas_env:
	store		R5,(R3)

; registre 10 = volume canal C
; B4=1 bit =M / M=0=>volume fixe / M=1=>volume enveloppe
; B3/B2/B1/B0 = volume fixe pour le canal C
;	Noise	 Tone
;	C B A    C B A
	loadb		(R1),R2						; registre 10
	add			R8,R1	

	move		R2,R4
	movei		#YM_DSP_registre10,R6
	moveq		#%1111,R3
	store		R4,(R6)					; sauvegarde la valeur de volume sur 16, pour DG
	movei		#YM_DSP_volE,R5
	and			R3,R4
	
	shlq		#2,R4					; volume sur 16 *4 
	load		(R14+R4),R4
	
	movei		#YM_DSP_volC,R6
	store		R4,(R6)

	movei		#YM_DSP_pointeur_sur_source_du_volume_C,R3

	btst		#4,R2
	jr			ne,DSP_lecture_registre10_pas_env
	nop

	move		R6,R5
	
DSP_lecture_registre10_pas_env:
	store		R5,(R3)



; registre 11 & 12 = frequence de l'enveloppe sur 16 bits
	loadb		(R1),R2						; registre 11 = 8 bits du bas
	add			R8,R1
	loadb		(R1),R3						; registre 12 = 8 bits du haut

	movei		#YM_frequence_predivise,R5
	add			R8,R1
	shlq		#8,R3
	load		(R5),R5						; R5=YM_frequence_predivise
	add			R2,R3						; R3 = frequence YM canal B

	jr			ne,DSP_lecture_registre11_12_pas_zero
	nop
	moveq		#0,R5
	jr			DSP_lecture_registre11_12_zero
	nop
	
DSP_lecture_registre11_12_pas_zero:	
	div			r3,R5

DSP_lecture_registre11_12_zero:	
	movei		#YM_DSP_increment_enveloppe,R2
	or			R5,R5
	store		R5,(R2)


; registre 13 = envelop shape
	loadb		(R1),R2						; registre 13 = Envelope shape control

	movei		#YM_DSP_registre13,R6
	move		R2,R5
	bclr		#7,R5					; supprimer le bit 7 puisque reserved
	add			R8,R1

	store		R5,(R6)					; sauvegarde la valeur env shape registre 13

; tester si bit 7 = 1 => ne pas modifier l'env en cours

	movei		#DSP_lecture_registre13_pas_env,R3
	btst		#7,R2
	jump		eq,(R3)

; - choix de la bonne enveloppe
	moveq		#%1111,R5
	; movei		#$FFF00000,R3						; 16 bits du haut = -16, virgule = 0
	moveq		#0,R3					; simplification ENV : offset =0000 0000
	and			R5,R2
	movei		#YM_DSP_offset_enveloppe,R5
	movei		#YM_DSP_pointeur_enveloppe_en_cours,R0
	store		R3,(R5)
	movei		#YM_DSP_liste_des_enveloppes_V2,R4
	shlq		#2,R2								; numero d'env dans registre 13 * 4
	add			R2,R4
	load		(R4),R4
	store		R4,(R0)								; pointe sur enveloppe

DSP_lecture_registre13_pas_env:
	addq				#2,R1			; arrondi a 4 pour lecture .L


; DG WoD
	;movei			#DSP_debut_sample_DG,R0
	;movei			#DSP_fin_sample_DG,R2
	load				(R1),R4
	movei			#.pas_de_nouveau_DG,R5
	cmpq			#0,R4
	jump				eq,(R5)
; nouveau DG
	moveq			#0,R6
	shlq				#nb_bits_virgule_offset,R4
	store				R6,(R1)
	addq				#4,R1
	load				(R1),R3
	shlq				#nb_bits_virgule_offset,R3
	movei			#DSP_pointeur_adresse_dg_a_virgule,R0
	movei			#DSP_pointeur_adresse_de_fin_dg_a_virgule,R2
	store				R4,(R0)
	store				R3,(R2)
.pas_de_nouveau_DG:


REG_main_sample1								.equr				R0
REG_main_SFX__location_entier0		.equr				R1
REG_main_SFX__location_end0			.equr				R2
REG_main_SFX__volume0					.equr				R3
; lecture SFX
; lecture valeurs SFX
; check si nouvelles valeurs
		movei			#PAULA_SFX_left,R14
		movei			#DSP_pas_valeur_SFX_left,REG_main_sample1
		load				(R14),REG_main_SFX__location_entier0
		cmpq			#0,REG_main_SFX__location_entier0
		jump				eq,(REG_main_sample1)
		nop
		load				(R14+1),REG_main_SFX__location_end0
		moveq			#0,REG_main_sample1
		load				(R14+2),REG_main_SFX__volume0
		store				REG_main_sample1,(R14)

		movei			#PAULA_SFX_left_private,R14								; loc/end/volume
		store				REG_main_SFX__location_entier0,(R14)
		store				REG_main_SFX__location_end0,(R14+1)
		store				REG_main_SFX__volume0,(R14+2)
DSP_pas_valeur_SFX_left:		

		movei			#PAULA_SFX_right,R14
		movei			#DSP_pas_de_nouvelle_valeur_SFX_right,REG_main_sample1
		load				(R14),REG_main_SFX__location_entier0
		cmpq			#0,REG_main_SFX__location_entier0
		jump				eq,(REG_main_sample1)
		nop
		load				(R14+1),REG_main_SFX__location_end0
		moveq			#0,REG_main_sample1
		load				(R14+2),REG_main_SFX__volume0
		store				REG_main_sample1,(R14)

		movei			#PAULA_SFX_right_private,R14								; loc/end/volume
		store				REG_main_SFX__location_entier0,(R14)
		store				REG_main_SFX__location_end0,(R14+1)
		store				REG_main_SFX__volume0,(R14+2)
DSP_pas_de_nouvelle_valeur_SFX_right:		















; flag pour le main
	movei			#flag_timer1,R0
	moveq			#1,R1
	store				R1,(R0)
	


;------------------------------------	
; return from interrupt Timer 1
	load	(r31),r12	; return address
	;bset	#10,r29		; clear latch 1 = I2S
	bset	#11,r13		; clear latch 1 = timer 1
	;bset	#12,r29		; clear latch 1 = timer 2
	bclr	#3,r13		; clear IMASK
	addq	#4,r31		; pop from stack
	addqt	#2,r12		; next instruction
	jump	t,(r12)		; return
	store	r13,(r16)	; restore flags


; ------------------- N/A ------------------
DSP_LSP_routine_interruption_Timer2_STOP:
	moveq		#DSP_STOP_flag_arret_main,REG_interrupt_TMP2			; launch timer 2 STOP
	bclr			#7,R29																						; clear Timer 2 Interrupt Enable Bit => OFF
	store			REG_interrupt_TMP2,(REG_interrupt_TMP1)
	
;------------------------------------	
; return from interrupt Timer 2
	load			(r31),R28	; return address
	bset			#12,R29		; clear latch 1 = timer 1
	addq			#4,R31		; pop from stack
	bclr			#3,R29		; clear IMASK
	addqt		#2,r28		; next instruction
	jump			t,(r28)		; return
	store			r29,(r30)	; restore flags



DSP_LSP_routine_interruption_Timer2:
; ------------------- N/A ------------------
; test STOP
		movei		#DSP_flag_STOP,REG_interrupt_TMP1
		load			(REG_interrupt_TMP1),REG_interrupt_TMP2
		cmpq		#DSP_STOP_flag_arret_Timer2,REG_interrupt_TMP2
		jr				eq,DSP_LSP_routine_interruption_Timer2_STOP
		nop



;DSP_pad1
;DSP_pad2
; lecture des 2 pads
; Pads : mask = xxxx xxCx xxBx 2580 147* oxAP 369# RLDU
; dispos : R0 à R12
	movei		#JOYSTICK,R0

	movei		#%00001111000000000000000000000000,R2		; mask port 1
	movei		#%00000000000000000000000000000011,R3		; mask port 1

	movei		#%11110000000000000000000000000000,R5		; mask port 2
	movei		#%00000000000000000000000000001100,R6		; mask port 2



; row 0
	MOVEI		#$817e,R1			; =81<<8 + 0111 1110 = (A Pause) + (Right Left Down Up) / 81 pour bit 15 pour output + bit 8 pour  conserver le son ON : pad 1 & 2
									; 1110 = row 0 of joypad = Pause A Up Down Left Right
	storew		R1,(R0)				; lecture row 0
	nop
	load		(R0),R1
	;movei		#$F000000C,R3		; mask port 2
	
; row0 = Pause A Up Down Left Right
; 0000 1111 0000 0000 0000 0000 0000 0011
;      RLDU                            Ap
	move		R1,R10				; stocke pour lecture port 2
	
	move		R1,R4
	move		R10,R7
	and			R3,R4		
	and			R6,R7		
	and			R2,R1				
	and			R5,R10				
	shlq		#8,R4				; R4=Ap xxxx xxxx
	shlq		#6,R7				; R4=Ap xxxx xxxx
	shrq		#24,R1				; R1=RLDU
	shrq		#28,R10				; R10=RLDU
	or			R4,R1
	or			R7,R10
	move		R1,R8
	move		R10,R9



; row 1
	MOVEI		#$81BD,R1			; #($81 << 8)|(%1011 << 4)|(%1101),(a2) ; (B D) + (1 4 7 *)
	storew		R1,(R0)				; lecture row 1
	nop
	load		(R0),R1
; row1 = 
; 0000 1111 0000 0000 0000 0000 0000 0011
;      147*                            BD
	move		R1,R10				; stocke pour lecture port 2
;row1 port 1&2

	move		R1,R4
	move		R10,R7
	and			R3,R4
	and			R6,R7		
	shlq		#20,R4
	shlq		#18,R7				
	and			R2,R1				
	and			R5,R10				
	shrq		#12,R1				; R1=147*
	shrq		#16,R10				; R10=147*
	or			R1,R4
	or			R7,R10
	or			R4,R8				; R8= BD xxxx 147* xxAp xxxx RLDU
	or			R10,R9


; row 2
	MOVEI		#$81DB,R1			; #($81 << 8)|(%1101 << 4)|(%1011),(a2) ; (C E) + (2 5 8 0)
	storew		R1,(R0)				; lecture row 2
	nop
	load		(R0),R1
	move		R1,R10				; stocke pour lecture port 2

; row2 = 
; 0000 1111 0000 0000 0000 0000 0000 0011
;      2580                            CE
; 24,8,22,12
	move		R1,R4
	move		R10,R7
	and			R3,R4
	and			R6,R7		
	shlq		#24,R4
	shlq		#22,R7				
	and			R2,R1				
	and			R5,R10				
	shrq		#8,R1				; R1=147*
	shrq		#12,R10				; R10=147*
	or			R1,R4
	or			R7,R10
	or			R4,R8				; R8= BD xxxx 147* xxAp xxxx RLDU
	or			R10,R9



; row 3
	MOVEI		#$81E7,R1			; #($81 << 8)|(%1110 << 4)|(%0111),(a2) ; (Option F) + (3 6 9 #)
	storew		R1,(R0)				; lecture row 3
	nop
	load		(R0),R1
; row3 = 
; 0000 1111 0000 0000 0000 0000 0000 0011
;      369#                            oF
; l10,r20,l8,r24
	move		R1,R10				; stocke pour lecture port 2

	move		R1,R4
	move		R10,R7
	and			R3,R4
	and			R6,R7		
	shlq		#10,R4
	shlq		#8,R7				
	and			R2,R1				
	and			R5,R10				
	shrq		#20,R1				; R1=147*
	shrq		#24,R10				; R10=147*
	or			R1,R4
	or			R7,R10
	or			R4,R8				; R8= BD xxxx 147* xxAp xxxx RLDU
	or			R10,R9

	movei		#DSP_pad1,R1
	movei		#DSP_pad2,R4
	
	not			R8
	not			R9
	store		R8,(R1)
	store		R9,(R4)
	
									

;------------------------------------	
; return from interrupt Timer 2
	load		(r31),R28	; return address
	bset		#12,R29		; clear latch 1 = timer 1
	addq		#4,R31		; pop from stack
	bclr		#3,R29		; clear IMASK
	addqt	#2,r28		; next instruction
	jump		t,(r28)		; return
	store		r29,(r30)	; restore flags














; ----------------------------------------------
; routine d'init du DSP
; registres bloqués par les interruptions : R29/R30/R31 ?
DSP_routine_init_DSP:
; assume run from bank 1
	movei	#DSP_ISP+(DSP_STACK_SIZE*4),r31			; init isp
	moveq	#0,r1
	moveta	r31,r31									; ISP (bank 0)
	movei	#DSP_USP+(DSP_STACK_SIZE*4),r31			; init usp
	
; -------------------------------------------------------------------------------
; calcul de la frequence prédivisee pour le YM
; ((YM_frequence_YM2149/16)*65536)/DSP_Audio_frequence

	movei	#YM_frequence_YM2149,r0
	shlq	#16-4-2,r0					; /16 puis * 65536
	
	movei	#DSP_frequence_de_replay_reelle_I2S,r2
	load	(r2),r2
	
	div		r2,r0
	or		r0,r0					; attente fin de division
	shlq	#2,r0					; ramene a *65536

	
	movei	#YM_frequence_predivise,r1
	store	r0,(r1)



;calcul de ( 1<<31) / frequence de replay réelle )

	moveq	#1,R0
	shlq	#31,R0
	div		r2,r0
	or		R0,R0
	
	movei	#DSP_UN_sur_frequence_de_replay_reelle_I2S,r1
	store	R0,(R1)


; calcul frequence DG 6258 => 6258/DSP_frequence_de_replay_reelle_I2S
	movei			#6258,R0
	;movei			#DSP_increment_DG_6258Hz,R4
	shlq				#nb_bits_virgule_offset,R0
	div				R2,R0
	or					R0,R0
	;store				R0,(R4)
	moveta		R0,DSP_REG_IRQ_increment_6258Hz


; registres alt fixes
	movei			#DSP_LSP_routine_interruption_I2S,R0
	moveta		R0,DSP_REG_IRQ_routine_I2S


; init SFX pointeurs silence
	movei			#silence,R0
	movei			#silence+2,R1
	shlq				#nb_bits_virgule_offset,R0
	shlq				#nb_bits_virgule_offset,R1
	movei			#PAULA_SFX_left_private,R14
	store				R0,(R14)
	store				R0,(R14+3)
	store				R1,(R14+1)
	store				R1,(R14+4)


; init I2S
	movei	#SCLK,r10
	movei	#SMODE,r11
	movei	#DSP_parametre_de_frequence_I2S,r12
	movei	#%001101,r13			; SMODE bascule sur RISING
	load	(r12),r12				; SCLK
	store	r12,(r10)
	store	r13,(r11)

; init Timer 1

	movei	#182150,R10				; 26593900 / 146 = 182150
	movei	#YM_frequence_replay,R11
	load	(R11),R11
	or		R11,R11
	div		R11,R10
	or		R10,R10
	move	R10,R13
	
	subq	#1,R13					; -1 pour parametrage du timer 1
	
	

; 26593900 / 50 = 531 878 => 2 × 73 × 3643 => 146*3643
	movei	#JPIT1,r10				; F10000
	;movei	#JPIT2,r11				; F10002
	movei	#146-1,r12				; Timer 1 Pre-scaler
	;movei	#3643-1,r13				; Timer 1 Divider  
	
	shlq	#16,r12
	or		R13,R12
	
	store	r12,(r10)				; JPIT1 & JPIT2



; init timer 2
	movei	#JPIT3,r10				; F10004
	;movei	#JPIT4,r11				; F10006
	movei	#145*65536,r12			; Timer 1 Pre-scaler
	movei	#955-1,r13				; 951=200hz
	or		R13,R12
	store	r12,(r10)				; JPIT1 & JPIT2



; enable interrupts
	movei	#D_FLAGS,r28
	movei	#D_I2SENA|D_TIM1ENA|D_TIM2ENA|REGPAGE|D_CPUENA,r29			; I2S+Timer 1+timer 2+CPU
	
	;movei	#D_I2SENA|D_TIM1ENA|REGPAGE,r29			; I2S+Timer 1
	
	;movei	#D_TIM1ENA|REGPAGE,r29					; Timer 1 only
	;movei	#D_I2SENA|REGPAGE,r29					; I2S only
	;movei	#D_TIM2ENA|REGPAGE,r29					; Timer 2 only
	
	store	r29,(r28)




; -------------------------------------------------------------------------------
; boucle principale DSP

DSP_boucle_centrale:
	movei			#DSP_flag_STOP,R0
	load				(R0),R1
	cmpq			#DSP_STOP_flag_STOP_NOW,R1
	jr					ne,.pas_STOP
	moveq			#DSP_STOP_flag_arret_I2S,R2
	movei			#DSP_LSP_routine_interruption_I2S_STOP,R3
	store				R2,(R0)
	moveta		R3,DSP_REG_IRQ_routine_I2S				; STOP routine I2S
.pas_STOP:
	
	cmpq			#DSP_STOP_flag_arret_main,R1
	jr					ne,.DSP_pas_stop_final
	nop
	movei		#D_CTRL,R20
	moveq		#0,R6
	store			R6,(R0)				; DSP_FLAG_STOP_DSP=0
	nop
	nop
.wait:
	jr				.wait
	store		R6,(R20)

	

.DSP_pas_stop_final:

	movei		#DSP_boucle_centrale,R0
	jump			(R0)
	nop

	
	
	
	.dphrase


; datas DSP
DSP_volume_SFX:		dc.l			volume_SFX		; 0-256
DSP_volume_music:	dc.l			volume_music		; 0-256

DSP_flag_STOP:		dc.l				0
vbl_counter_replay_DSP:				dc.l			0
YM_DSP_pointeur_sur_table_des_pointeurs_env_Buzzer:		dc.l		0

YM_DSP_registre8:			dc.l			0
YM_DSP_registre9:			dc.l			0
YM_DSP_registre10:			dc.l			0
YM_DSP_registre13:			dc.l			0

DSP_frequence_de_replay_reelle_I2S:					dc.l			0
DSP_UN_sur_frequence_de_replay_reelle_I2S:			dc.l			0
DSP_parametre_de_frequence_I2S:						dc.l			0

YM_DSP_increment_canal_A:			dc.l			0
YM_DSP_increment_canal_B:			dc.l			0
YM_DSP_increment_canal_C:			dc.l			0
YM_DSP_increment_Noise:				dc.l			0
YM_DSP_increment_enveloppe:			dc.l			0

YM_DSP_Mixer_TA:					dc.l			0
YM_DSP_Mixer_TB:					dc.l			0
YM_DSP_Mixer_TC:					dc.l			0
YM_DSP_Mixer_NA:					dc.l			0
YM_DSP_Mixer_NB:					dc.l			0
YM_DSP_Mixer_NC:					dc.l			0

YM_DSP_volA:					dc.l			$1234
YM_DSP_volB:					dc.l			$1234
YM_DSP_volC:					dc.l			$1234

YM_DSP_volE:					dc.l			0
YM_DSP_offset_enveloppe:		dc.l			0
YM_DSP_pointeur_enveloppe_en_cours:	dc.l		0

YM_DSP_pointeur_sur_source_du_volume_A:				dc.l		YM_DSP_volA
YM_DSP_pointeur_sur_source_du_volume_B:				dc.l		YM_DSP_volB
YM_DSP_pointeur_sur_source_du_volume_C:				dc.l		YM_DSP_volC

YM_DSP_position_offset_A:		dc.l			0
YM_DSP_position_offset_B:		dc.l			0
YM_DSP_position_offset_C:		dc.l			0

YM_DSP_position_offset_Noise:	dc.l			0
YM_DSP_current_Noise:			dc.l			$12071971
YM_DSP_current_Noise_mask:		dc.l			0
YM_DSP_Noise_seed:				dc.l			$12071971





YM_DSP_table_de_volumes:
; 15 bits non signés
	dc.l				0,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767


; table volumes Amiga:
	;dc.l				$00*$c0, $00*$c0, $00*$c0, $00*$c0, $01*$c0, $02*$c0, $02*$c0, $04*$c0, $05*$c0, $08*$c0, $0B*$c0, $10*$c0, $18*$c0, $22*$c0, $37*$c0, $55*$c0
	
; volume 4 bits en 8 bits
; $00 $00 $00 $00 $01 $02 $02 $04 $05 $08 $0B $10 $18 $22 $37 $55
; ramené à 16383 ( 65535 / 4)
; *$c0

	;dc.l				0,161/2,265/2,377/2,580/2,774/2,1155/2,1575/2,2260/2,3088/2,4570/2,6233/2,9330/2,13187/2,21220/2,32767/2

					; 62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767



YM_DSP_table_prediviseur:
				dc.l		0,4,10,16,50,64,100,200	

; flags pour nb octets à lire
;YM_flag_effets_sur_les_voies:			dc.l				0


;PSG_compteur_frames_restantes:			dc.l		0
;YM_pointeur_actuel_ymdata:				dc.l		0


	
; simplification gestion des enveloppes
; de 0 47
; boucle sur 16
;
YM_DSP_liste_des_enveloppes_V2:
	dc.l		YM_DSP_enveloppe00xx_V2,YM_DSP_enveloppe00xx_V2,YM_DSP_enveloppe00xx_V2,YM_DSP_enveloppe00xx_V2
	dc.l		YM_DSP_enveloppe01xx_V2,YM_DSP_enveloppe01xx_V2,YM_DSP_enveloppe01xx_V2,YM_DSP_enveloppe01xx_V2
	dc.l		YM_DSP_enveloppe1000_V2,YM_DSP_enveloppe1001_V2,YM_DSP_enveloppe1010_V2,YM_DSP_enveloppe1011_V2
	dc.l		YM_DSP_enveloppe1100_V2,YM_DSP_enveloppe1101_V2,YM_DSP_enveloppe1110_V2,YM_DSP_enveloppe1111_V2

YM_DSP_enveloppe00xx_V2:
	dc.l				32767,21220,13187,9330,6233,4570,3088,2260,1575,1155,774,580,377,265,161,62
	dc.l				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.l				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
YM_DSP_enveloppe01xx_V2:
	dc.l				62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767
	dc.l				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.l				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
YM_DSP_enveloppe1000_V2:
	dc.l				32767,21220,13187,9330,6233,4570,3088,2260,1575,1155,774,580,377,265,161,62
	dc.l				32767,21220,13187,9330,6233,4570,3088,2260,1575,1155,774,580,377,265,161,62
	dc.l				32767,21220,13187,9330,6233,4570,3088,2260,1575,1155,774,580,377,265,161,62
YM_DSP_enveloppe1001_V2:
	dc.l				32767,21220,13187,9330,6233,4570,3088,2260,1575,1155,774,580,377,265,161,62
	dc.l				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.l				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
YM_DSP_enveloppe1010_V2:
	dc.l				32767,21220,13187,9330,6233,4570,3088,2260,1575,1155,774,580,377,265,161,62
	dc.l				62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767
	dc.l				32767,21220,13187,9330,6233,4570,3088,2260,1575,1155,774,580,377,265,161,62
YM_DSP_enveloppe1011_V2:
	dc.l				32767,21220,13187,9330,6233,4570,3088,2260,1575,1155,774,580,377,265,161,62
	dc.l				32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767
	dc.l				32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767
YM_DSP_enveloppe1100_V2:
	dc.l				62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767
	dc.l				62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767
	dc.l				62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767
YM_DSP_enveloppe1101_V2:
	dc.l				62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767
	dc.l				32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767
	dc.l				32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767,32767
YM_DSP_enveloppe1110_V2:
	dc.l				62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767
	dc.l				32767,21220,13187,9330,6233,4570,3088,2260,1575,1155,774,580,377,265,161,62
	dc.l				62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767
YM_DSP_enveloppe1111_V2:
	dc.l				62,161,265,377,580,774,1155,1575,2260,3088,4570,6233,9330,13187,21220,32767
	dc.l				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	dc.l				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


flag_timer1:				; 1=timer 1 terminé
					dc.l				0
	.phrase	


DSP_debut_sample_DG:			dc.l				silence
DSP_fin_sample_DG:				dc.l				silence+2
;DSP_increment_DG_6258Hz:		dc.l				0

DSP_pointeur_adresse_dg_a_virgule:			dc.l				silence
DSP_pointeur_adresse_de_fin_dg_a_virgule:		dc.l			silence+2




; SFX channels
PAULA_SFX_left_private:
PAULA_sample_location_sfx1:				dc.l			silence<<nb_bits_virgule_offset								;  0 : interne
PAULA_sample_end_sfx1:						dc.l			(silence+2)<<nb_bits_virgule_offset						;  2 : interne
PAULA_volume_sfx1:								dc.l			0																				;  3 : volume

PAULA_SFX_right_private:
PAULA_sample_location_sfx2:				dc.l			silence<<nb_bits_virgule_offset								;  0 : interne
PAULA_sample_end_sfx2:						dc.l			(silence+2)<<nb_bits_virgule_offset						;  2 : interne
PAULA_volume_sfx2:								dc.l			0																				;  3 : volume


PAULA_SFX_left:
	dc.l			silence<<nb_bits_virgule_offset								;  0 : interne
	dc.l			(silence+2)<<nb_bits_virgule_offset						;  2 : interne
	dc.l			0																				;  3 : volume

PAULA_SFX_right:
	dc.l			silence<<nb_bits_virgule_offset								;  0 : interne
	dc.l			(silence+2)<<nb_bits_virgule_offset						;  2 : interne
	dc.l			0																				;  3 : volume




; pads
; Pads : mask = xxxxxxCx xxBx2580 147*oxAP 369#RLDU
; U235 format
;------------------------------------------------------------------------------------------------ Joypad Section

										; Pads : mask = xxxxxxCx xxBx2580 147*oxAP 369#RLDU

; 												Bit numbers for buttons in the mask for testing individual bits
U235SE_BBUT_UP			EQU		0		; Up
U235SE_BBUT_U			EQU		0
U235SE_BBUT_DOWN		EQU		1		; Down
U235SE_BBUT_D			EQU		1
U235SE_BBUT_LEFT		EQU		2		; Left
U235SE_BBUT_L			EQU		2
U235SE_BBUT_RIGHT		EQU		3		; Right
U235SE_BBUT_R			EQU		3		
U235SE_BBUT_HASH		EQU		4		; Hash (#)
U235SE_BBUT_9			EQU		5		; 9
U235SE_BBUT_6			EQU		6		; 6
U235SE_BBUT_3			EQU		7		; 3
U235SE_BBUT_PAUSE		EQU		8		; Pause
U235SE_BBUT_A			EQU		9		; A button
U235SE_BBUT_OPTION		EQU		11		; Option
U235SE_BBUT_STAR		EQU		12		; Star 
U235SE_BBUT_7			EQU		13		; 7
U235SE_BBUT_4			EQU		14		; 4
U235SE_BBUT_1			EQU		15		; 1
U235SE_BBUT_0			EQU		16		; 0 (zero)
U235SE_BBUT_8			EQU		17		; 8
U235SE_BBUT_5			EQU		18		; 5
U235SE_BBUT_2			EQU		19		; 2
U235SE_BBUT_B			EQU		21		; B button
U235SE_BBUT_C			EQU		25		; C button

; 												Numerical representations
U235SE_BUT_UP			EQU		1		; Up
U235SE_BUT_U			EQU		1
U235SE_BUT_DOWN			EQU		2		; Down
U235SE_BUT_D			EQU		2
U235SE_BUT_LEFT			EQU		4		; Left
U235SE_BUT_L			EQU		4
U235SE_BUT_RIGHT		EQU		8		; Right
U235SE_BUT_R			EQU		8		
U235SE_BUT_HASH			EQU		16		; Hash (#)
U235SE_BUT_9			EQU		32		; 9
U235SE_BUT_6			EQU		64		; 6
U235SE_BUT_3			EQU		$80		; 3
U235SE_BUT_PAUSE		EQU		$100	; Pause
U235SE_BUT_A			EQU		$200	; A button
U235SE_BUT_OPTION		EQU		$800	; Option
U235SE_BUT_STAR			EQU		$1000	; Star 
U235SE_BUT_7			EQU		$2000	; 7
U235SE_BUT_4			EQU		$4000	; 4
U235SE_BUT_1			EQU		$8000	; 1
U235SE_BUT_0			EQU		$10000	; 0 (zero)
U235SE_BUT_8			EQU		$20000	; 8
U235SE_BUT_5			EQU		$40000	; 5
U235SE_BUT_2			EQU		$80000	; 2
U235SE_BUT_B			EQU		$200000	; B button
U235SE_BUT_C			EQU		$2000000; C button

; xxxxxxCx xxBx2580 147*oxAP 369#RLDU
DSP_pad1:				dc.l		0
DSP_pad2:				dc.l		0


;---------------------
; FIN DE LA RAM DSP
YM_DSP_fin:
;---------------------


SOUND_DRIVER_SIZE			.equ			YM_DSP_fin-DSP_base_memoire
	.print	"--- Sound driver code size (DSP): ", /u SOUND_DRIVER_SIZE, " bytes / 8192 ---"


	
	.68000

	.include		"replay_madmax.s"
	


	.even
	.phrase
curseur_Y_min		.equ		8
curseur_x:	dc.w		0
curseur_y:	dc.w		curseur_Y_min


chaine_replay_YM7:				
	dc.b	"A:"
chaine_replay_TA:
	dc.b	"T"
chaine_replay_NA:
	dc.b	"N"
chaine_replay_envA:
	dc.b	"E"
chaine_replay_SID_A:
	dc.b	"S"
chaine_replay_DG_A:
	dc.b	"D  "
	dc.b	"B:"
chaine_replay_TB:
	dc.b	"T"
chaine_replay_NB:
	dc.b	"N"
chaine_replay_envB:
	dc.b	"E"
chaine_replay_SID_B:
	dc.b	"S"
chaine_replay_DG_B:
	dc.b	"D  "
	dc.b	"C:"
chaine_replay_TC:
	dc.b	"T"
chaine_replay_NC:
	dc.b	"N"
chaine_replay_envC:
	dc.b	"E"
chaine_replay_SID_C:
	dc.b	"S"
chaine_replay_DG_C:
	dc.b	"D  "
chaine_replay_Sinus:
	dc.b	"s"
chaine_replay_Buzzer:
	dc.b	"Z ",0

chaine_playing_YM7_MONO:		dc.b	"mono.",10,10,0
chaine_playing_YM7_STEREO:		dc.b	"stereo.",10,10,0
chaine_playing_YM7:				dc.b	"Now playing in ",0
chaine_HZ_init_YM7:				dc.b	" Hz.",10,0
chaine_replay_frequency:		dc.b	"Replay frequency : ",0
chaine_RAM_DSP:					dc.b	"DSP RAM available while running : ",0


couleur_char:				dc.b		25

	even
fonte:	
	.include	"../fonte1plan.s"
	even
	
            .dphrase
stoplist:		dc.l	0,4




;YM_table_frequences_Sinus_Sid_Amiga:		dc.w	567, 283, 142, 71
; 00: 6258 Hz
; 01: 12517 Hz
; 10: 25033 Hz
; 11: 50066 Hz



		.dphrase

debut_ram_libre_DSP:		dc.l			YM_DSP_fin
debut_ram_libre:			dc.l			FIN_RAM

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

	.phrase
silence:				dc.b					0,0,0,0
fin_silence:

	.dphrase
	.phrase
taille_une_entree_buffer_asynchrone = 6				; 14*.B + align to 4 =16 / + 2*.L=8 => total = 24 octets => 6 .L
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


speech:
	.incbin		"../SPEECH.SEQ"
	.phrase

	.bss
	.phrase
DEBUT_BSS:
            .dphrase


frequence_Video_Clock:					ds.l				1
frequence_Video_Clock_divisee :			.ds.l				1

YM_nombre_de_frames_totales:			ds.l				1
YM_frequence_replay:					ds.l				1


YM_nb_registres_par_frame:				ds.w				1
	.dphrase

YM_pointeur_origine_ymdata:		ds.l		1
YM_frequence_predivise:			ds.l		1
	.phrase

PSG_ecart_entre_les_registres_ymdata:		ds.l			1

YM_byte_streams_count:					ds.w				1

		.phrase


; pointeur pour init
YM_minimal_memory_buffer_size:			ds.l				1



	.phrase
buffers_paula_asynchrones:
		ds.b				taille_une_entree_buffer_asynchrone*4*8


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
ecran1:				ds.b		320*256				; 8 bitplanes

FIN_RAM:


