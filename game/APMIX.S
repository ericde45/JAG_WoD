; - petit bruit aigu sur le replay jaguar ?
; - son étrange en 1"38 de la vidéo https://www.youtube.com/watch?v=ChNkpqiaK0Q&list=PLErsx10Ke4uyf3dj4RaqWtBQRNx-pfoRb&index=2
;			: absent du replay envoyé
; OK : - lors du forcage, charger le registre de stockage des octets avec les 4 bons octets , modulo 4 de source 
; OK - reprendre la virgule lors du forcage ? NON
; OK - reprendre la virgule lors du repeat : OUI
; OK - possible problème de silence ??? taille=1 ??? et même taille = 0 ( mais volume=0 donc ...)
; OK : de externe => interne : doit etre modulo 4 : NON
; A voir, deja OK ? : essayer avec une version sans lecture de 4 octets et donc taille = 1 word devient acceptable


; - dma off for channel
; - wait 4 scanlines
; - ecriture dmacon : SET+channel
; - prise en compte du changement




; OK - sourcer proprement les 2 tables de saut : 1 sur 2
; OK - remplacer les DFF par paula émulé
; OK - gérer le dmacon pour SET
; OK - gérer le dmacon pour STOP/clear
; - repenser la gestion du dmacon
; - nettoyer le code, sprites, protection, 
; OK - decouper les binaires avec cutter : differents COSO + le bloc de samples


;L006A		coso
;L006B		coso
;L006C		coso
;L006D		coso
;L006E		coso
;L006F		coso
;L0070		coso

; L0071		samples


APMIX_entry_point:
      BRA       APMIX__init 					; init	D0=numero de morceau => choix du fichier / 1-7
      BRA       APMIX_play						; L0012 					; play

	  
; ---------- init -----------		  
;L0008:
APMIX__init:
MOVEM.L   A0-A6/D0-D7,-(A7) 
      MOVEQ     #$23,D1 
      LEA       L006A(PC),A0				; A0=songfile 1
      CMP.W     #3,D0 						; 
      BLT       L000E 
      CMP.W     #3,D0 
      BNE.S     L0009 
      MOVEQ     #5,D1 						; D0=3
      LEA       L006B(PC),A0				; A0=songfile 2
      SUBQ.W    #2,D0 
      BRA.S     L000E 
L0009:CMP.W     #4,D0 
      BNE.S     L000A 
      MOVEQ     #$14,D1 
      LEA       L006C(PC),A0				; A0=songfile 3
      SUBQ.W    #3,D0 
      BRA.S     L000E 
L000A:CMP.W     #5,D0 
      BNE.S     L000B 
      MOVEQ     #$35,D1 
      LEA       L006D(PC),A0				; A0=songfile 4
      SUBQ.W    #4,D0 
      BRA.S     L000E 
L000B:CMP.W     #6,D0 
      BNE.S     L000C 
      MOVEQ     #$14,D1 
      LEA       L006E(PC),A0				; A0=songfile 5
      SUBQ.W    #5,D0 
      BRA.S     L000E 
L000C:CMP.W     #7,D0 
      BNE.S     L000D 
      MOVEQ     #$28,D1 
      LEA       L006F(PC),A0				; A0=songfile 6
      SUBQ.W    #6,D0 
      BRA.S     L000E 
L000D:CMP.W     #8,D0 
      BNE.S     L000E 
      MOVEQ     #$14,D1 
      LEA       L0070(PC),A0				; A0=songfile 7
      SUBQ.W    #7,D0 
L000E:
		BSR       L0011 					; soundinit
      TST.W     D0
      BNE.S     L000F 
      LEA       L0054(PC),A6				; D0=00
      ST        (A6)
      BSR       APMIX_play 						; play music
      BRA.S     L0010 						; on quitte
L000F:MOVEA.L   L0067(PC),A1
      SUBQ.W    #1,D0 
      ADD.W     D0,D0 
      MOVE.W    D0,D1 
      ADD.W     D0,D0 
      ADD.W     D1,D0 
      ADDA.W    D0,A1 
      MOVE.W    (A1)+,D0
      MOVE.W    (A1)+,D1
      LEA       L0053(PC),A6
      MOVE.W    (A1),(A6)+
      MOVE.W    (A1)+,(A6)+ 
      BSR       L0039 
L0010:MOVEM.L   (A7)+,A0-A6/D0-D7 
      RTS 
	  
; soundinit	  
L0011:LEA       L0068(PC),A1
      MOVE.W    D1,(A1) 
      ;BSET      #1,$BFE001					; low pass filter
	  
      LEA       L0066(PC),A6					; L0066=sogbase
      MOVE.L    A0,(A6) 
      MOVEA.L   4(A0),A1
      ADDA.L    A0,A1 
      LEA       L0061(PC),A6
      MOVE.L    A1,(A6) 
      MOVEA.L   8(A0),A1
      ADDA.L    A0,A1 
      LEA       L0062(PC),A6
      MOVE.L    A1,(A6) 
      MOVEA.L   12(A0),A1 
      ADDA.L    A0,A1 
      LEA       L0060(PC),A6
      MOVE.L    A1,(A6) 
      MOVEA.L   16(A0),A1 
      ADDA.L    A0,A1 
      LEA       L0063(PC),A6
      MOVE.L    A1,(A6) 
      MOVEA.L   20(A0),A1 
      ADDA.L    A0,A1 
      LEA       L0067(PC),A6
      MOVE.L    A1,(A6) 
      LEA       L0064(PC),A6
      MOVEA.L   24(A0),A1 
      ADDA.L    A0,A1 
      MOVE.L    A1,(A6) 
      LEA       L0065(PC),A6
      LEA       APMIX__debut_des_samples+10(PC),A1				; 
      MOVE.L    A1,(A6) 
      RTS 
	  
;-----------------------------------------
	; play
APMIX_play:
	MOVEM.L   A0-A6/D0-D7,-(A7) 
	
		MOVEQ     #0,D7 

; repeat location = 0 pour simulation dmacon forcé
	  lea			Paula_custom,a6
	  move.l		d7,12(a6)				; voie A
	  move.l		d7,12+16(a6)			; voie B
	  move.l		d7,12+32(a6)			; voie C
	  move.l		d7,12+48(a6)			; voie D
		
      LEA       L0053(PC),A0
      TST.W     4(A0) 
      BEQ.S     L0025 
      ;MOVE.W    #$F,dmacon_local		; $DFF096 
		move.l		#$F,dmacon_current_frame			; tous les canaux = STOP
	  
      MOVE.W    D7,channela+8			;$DFF0A8				; AUD0VOL
      MOVE.W    D7,channelb+8			; $DFF0B8				; AUD1VOL
      MOVE.W    D7,channelc+8			;	$DFF0C8				; AUD2VOL
	  
      MOVEM.L   (A7)+,A0-A6/D0-D7 
      RTS 
L0025:LEA       L005F(PC),A5
      SUBQ.W    #1,(A0)+
      BNE.S     L0026 
; gestion volume, note et instrument	  
      MOVE.W    (A0),-(A0)
      MOVE.W    D7,(A5) 
      ;LEA       $DFF000,A6
	  lea			Paula_custom-$A0,a6
      LEA       L0055(PC),A0
      BSR       L002F 
      BSR       L003B 
      MOVE.L    D0,$A6(A6)					; period + volume d'un coup voix 0/A
      LEA       L0058(PC),A0
      BSR       L002F 
      BSR       L003B 
      MOVE.L    D0,$B6(A6)					; period + volume d'un coup voix 1/B
      LEA       L005B(PC),A0
      BSR       L002F 
      BSR       L003B 
      MOVE.L    D0,$C6(A6)					; period + volume d'un coup voix 2/C
	  
  
      BRA.S     L0027 
	  
L0026:
; gestion uniquement volume+note, pas d'instruments
		MOVE.W    D7,(A5) 
      ;LEA       $DFF000,A6
	  lea			Paula_custom-$A0,a6
      LEA       L0055(PC),A0
      BSR       L003B 
      MOVE.L    D0,$A6(A6)				; period + volume d'un coup voix 0/A
      LEA       L0058(PC),A0
      BSR       L003B 
      MOVE.L    D0,$B6(A6)			; period + volume d'un coup voix 1/B
      LEA       L005B(PC),A0
      BSR       L003B 
      MOVE.L    D0,$C6(A6)			; period + volume d'un coup voix 2/C
	  
  
	  
L0027:MOVE.W    (A5),D7 					; valeur pour DMACON
      BEQ	     L002B 							; pas de changement pour les instruments ?
      ORI.W     #$8000,D7 						; registre pour dmacon en mode SET
      MOVEA.L   L0056(PC),A0
      MOVEA.L   L0059(PC),A1
      MOVEA.L   L005C(PC),A2
      MOVE.W    L0057(PC),D0
      MOVE.W    L005A(PC),D1
      MOVE.W    L005D(PC),D2
      MOVE.W    D7,D6 
      ;ANDI.W    #6,D6 					; %0110
      ;BEQ.S     L002A 
      ;CMP.W     #6,D6 
      ;BEQ.S     L0028 
      ;CMP.W     #4,D6 
      ;BNE.S     L0029 
L0028:
		;BSR.S     L002C 											; attente 1 raster line
      ; BSR.S     L002C  											; attente 1 raster line
      ; BSR.S     L002C  											; attente 1 raster line
      ; BSR.S     L002C  											; attente 1 raster line
L0029:
		; BSR.S     L002C  											; attente 1 raster line
		; BSR.S     L002C  											; attente 1 raster line
L002A:

	;MOVE.W    D7,$96(A6)					; DMACON forcé !!!!
	;ext.l		d7
	move.l	d7,dmacon_current_frame


				.if			1=0
				or.l	#DSPINT0,D_CTRL								; interrupt pour prise en compte des valeurs HIPPEL par le DSP
			move.l		d0,-(sp)
.waitint1:
				nop
				move.l	D_CTRL,d0
				btst	#6,d0
				bne.s	.waitint1
			move.l		(sp)+,d0
			.endif
			
			; identique : location et length repeat vers interne
				lea				$a0(a6),a6
				btst				#0,d7			; test dmacon
				beq.s			dmacon_pas_force_voie0
				move.l			(a6),12(a6)					; location : repeat vers interne / voie A
				move.w			4(a6),10(a6)			; length : repeat vers interne / voie A
dmacon_pas_force_voie0:
				btst				#1,d7			; test dmacon
				beq.s			dmacon_pas_force_voie1
				move.l			16(a6),28(a6)					; location : repeat vers interne / voie B
				move.w			20(a6),26(a6)			; length : repeat vers interne / voie B
dmacon_pas_force_voie1:
				btst				#2,d7			; test dmacon
				beq.s			dmacon_pas_force_voie2
				move.l			32(a6),44(a6)					; location : repeat vers interne / voie C
				move.w			36(a6),42(a6)			; length : repeat vers interne / voie C
dmacon_pas_force_voie2:
				btst				#3,d7			; test dmacon
				beq.s			dmacon_pas_force_voie3
				move.l			48(a6),60(a6)					; location : repeat vers interne / voie D
				move.w			52(a6),58(a6)			; length : repeat vers interne / voie D
dmacon_pas_force_voie3:				
				lea				-$a0(a6),a6
	

	; => TO PAULA / force externes vers internes
	; - interruption
	; - attente fin d'interrution
	
	
	  
	
      ;BSR.S     L002C  											; attente 1 raster line
; mets les repeats suivants, dans registres externes	  
      MOVE.L    A0,$A0(A6)							; audio 0 location
      MOVE.W    D0,$A4(A6)						; audio 0 length
      MOVE.L    A1,$B0(A6)							; audio 1 location
      MOVE.W    D1,$B4(A6)						; audio 1 length
      MOVE.L    A2,$C0(A6)							; audio 2 location
      MOVE.W    D2,$C4(A6)						; audio 2 length

L002B:


		MOVEM.L   (A7)+,A0-A6/D0-D7 
      RTS 
	  
L002E:
		RTS 
; gestion avec changement instruments / arret instruments 
L002F:SUBQ.B    #1,40(A0) 
      BPL.S     L002E 
      MOVE.B    41(A0),40(A0) 
L0030:MOVEA.L   28(A0),A1 
L0031:MOVE.B    (A1)+,D0
      CMP.B     #$FF,D0 
      BNE.S     L0033 
      MOVEA.L   8(A0),A3
      MOVEA.L   4(A0),A2
      ADDA.W    38(A0),A2 
      CMPA.L    A3,A2 
      BNE.S     L0032 
      MOVE.W    D7,38(A0) 					; bouclage
      MOVEA.L   4(A0),A2
L0032:MOVEQ     #0,D1 
      MOVE.B    (A2)+,D1
      MOVE.B    (A2)+,59(A0)
      MOVE.B    (A2),48(A0) 
      ADD.W     D1,D1 
      MOVEA.L   L0060(PC),A3
      ADDA.W    D1,A3 
      MOVEA.W   (A3),A3 
      ADDA.L    L0066(PC),A3
      MOVE.L    A3,28(A0) 
      ADDI.W    #$C,38(A0)
      BRA.S     L0030 
L0033:CMP.B     #$FE,D0 
      BNE.S     L0034 
      MOVE.B    (A1),41(A0) 
      MOVE.B    (A1)+,40(A0)
      BRA.S     L0031 
L0034:CMP.B     #$FD,D0 
      BNE.S     L0035 
      MOVE.B    (A1),41(A0) 
      MOVE.B    (A1)+,40(A0)
      MOVE.L    A1,28(A0) 
      RTS 
L0035:MOVE.B    D0,46(A0) 
      MOVE.B    (A1)+,D1
      MOVE.B    D1,47(A0) 
      ANDI.W    #$E0,D1 
      BEQ.S     L0036 
      MOVE.B    (A1)+,56(A0)
L0036:MOVE.L    A1,28(A0) 
      MOVE.L    D7,12(A0) 
      TST.B     D0
      BMI       L0038 
      MOVE.B    47(A0),D1 
      ANDI.W    #$1F,D1 
      ADD.B     48(A0),D1 
      MOVEA.L   L0062(PC),A2
      ADD.W     D1,D1 
      ADDA.W    D1,A2 
      MOVEA.W   (A2),A2 
      ADDA.L    L0066(PC),A2
      MOVE.W    D7,36(A0) 
      MOVE.B    (A2),49(A0) 
      MOVE.B    (A2)+,50(A0)
      MOVEQ     #0,D1 
      MOVE.B    (A2)+,D1
      MOVE.B    (A2)+,53(A0)
      MOVEQ     #0,D0 
      MOVE.B    #$40,61(A0) 
      MOVE.B    (A2)+,D0
      MOVE.B    D0,54(A0) 
      MOVE.W    D0,44(A0) 
      MOVE.B    (A2)+,55(A0)
      MOVE.L    A2,20(A0) 
      MOVEA.L   L0061(PC),A2
      BTST      #6,47(A0) 
      BEQ.S     L0037 
      MOVE.B    56(A0),D1 
L0037:ADD.W     D1,D1 
      ADDA.W    D1,A2 
      MOVEA.W   (A2),A2 
      ADDA.L    L0066(PC),A2
      MOVE.L    A2,24(A0) 
      MOVE.W    D7,34(A0) 
      MOVE.B    D7,52(A0) 
      MOVE.B    D7,51(A0) 
L0038:RTS 


; fait partie de l'init
L0039:
	;LEA       L0021(PC),A0
     ; LEA       L0022(PC),A1
     ; MOVE.L    A1,(A0) 
     ; LEA       L0023(PC),A0
     ; CLR.W     (A0)
      ;BSR       L0018 
      MOVEQ     #0,D5 
      ;LEA       $DFF000,A6							; base custom
	  lea			Paula_custom-$A0,a6
      ;MOVE.W    #$F,$96(A6) 						; dmacon, coupe tout l'audio
      ;MOVE.W    #$780,$9A(A6) 					; Interrupt enable bits / $780 = %b 0000 0111 1000 0000 => AUD0/AUD1/AUD2/AUD3
      MOVE.W    D0,D7 
      MULU      #$C,D7
      MOVE.W    D1,D6 
      ADDQ.W    #1,D6 
      MULU      #$C,D6
      MOVEQ     #2,D0 								; 3 voies
      LEA       L0055(PC),A0
      LEA       L0051(PC),A1
      LEA       L005E(PC),A2
      LEA       L0052(PC),A5
	  
L003A:MOVE.L    A1,20(A0) 
      MOVE.L    A1,24(A0) 
      MOVE.B    #1,49(A0) 
      MOVE.B    #1,50(A0) 
      SF        51(A0)
      MOVE.W    D5,36(A0) 
      SF        52(A0)
      SF        53(A0)
      SF        54(A0)
      MOVE.W    #0,44(A0) 
      SF        55(A0)
      SF        56(A0)
      ST        57(A0)
      MOVE.W    D5,40(A0) 
      SF        58(A0)
      SF        60(A0)
      MOVE.W    D5,34(A0) 
      MOVE.L    D5,12(A0) 
      MOVE.W    D5,32(A0) 
      MOVE.W    (A2)+,D1							; A0/B0/C0
      MOVE.W    (A2)+,D3							; 00/03/06
      DIVU      #3,D3 
      MOVEQ     #0,D4 
      BSET      D3,D4 
      MOVE.W    D4,42(A0) 							; mask pour dmacon
      MULU      #3,D3 
      ANDI.L    #$FF,D3 
      ANDI.L    #$FF,D1 
	  
      ADD.L     A6,D1 									; + $DFF000
      MOVEA.L   D1,A4 							
      MOVE.L    #silence,(A4)+							; init valeur location PAULA
      MOVE.W    #1,(A4)+                            ; length
      MOVE.W    D5,(A4)+                            ; clear period = 0 
      MOVE.W    D5,(A4)+                            ; clear volume = 0 
      MOVE.L    D1,0(A0)                             ; stocke le pointeur sur les registres paula $DFF0x0
	  
  
      MOVE.L    L0063(PC),4(A0) 
      MOVE.L    L0063(PC),8(A0) 
      ADD.L     D6,8(A0)
      ADD.L     D3,8(A0)
      ADD.L     D7,4(A0)
      ADD.L     D3,4(A0)
      MOVE.W    #$C,38(A0)
      MOVEA.L   4(A0),A3
      MOVEQ     #0,D1 
      MOVE.B    (A3),D1 
      ADD.W     D1,D1 
      MOVEA.L   L0060(PC),A4
      ADDA.W    D1,A4 
      MOVEA.W   (A4),A4 
      ADDA.L    L0066(PC),A4
      MOVE.L    A4,28(A0) 
      MOVE.B    1(A3),59(A0)
      MOVE.B    2(A3),48(A0)
      LEA       62(A0),A0 
      DBF       D0,L003A
	  
      LEA       L0053(PC),A0
      MOVE.W    #1,(A0) 
      MOVE.W    D5,4(A0)
      RTS 
; --------------------------------	  
; gestion pour changer d'instruments + retour : D0=note+volume  
	  
	  
L003B:TST.B     52(A0)
      BEQ.S     L003C 
      SUBQ.B    #1,52(A0) 
      BRA       L0042 
L003C:MOVEA.L   24(A0),A1 
      ADDA.W    34(A0),A1 
L003D:MOVEQ     #0,D0 
      MOVE.B    (A1)+,D0
      CMP.W     #$E0,D0 
      BLT       L0041 
      SUBI.W    #$E0,D0 
      ADD.W     D0,D0 
      MOVE.W    L003E(PC,D0.W),D0 
      JMP       L003F(PC,D0.W)
L003E:				; table de sauts, 10 entrées
		dc.w			APMIX_saut1_001E-L003F
		dc.w			APMIX_saut2_01A6-L003F
		dc.w			APMIX_saut2_0114-L003F
		dc.w			APMIX_saut2_0010-L003F
		dc.w			APMIX_saut2_0166-L003F
		dc.w			APMIX_saut2_0114-L003F
		dc.w			APMIX_saut2_0166-L003F
		dc.w			APMIX_saut2_002E-L003F
		dc.w			APMIX_saut2_0000-L003F
		dc.w			APMIX_saut2_0086-L003F
		;DC.B      $00,$1E,$01,$A6,$01,$14,$00,$10 
		;DC.B      $01,'f',$01,$14,$01,'f',$00,'.' 
		;DC.B      $00,$00,$00,$86 
		
APMIX_saut2_0000:
L003F:
		MOVE.B    (A1)+,52(A0)
      ADDQ.W    #2,34(A0) 
      BRA.S     L003B
	  
      ADDQ.W    #2,34(A0) 
      BRA.S     L003D
	  
APMIX_saut2_0010:
      ADDQ.W    #3,34(A0) 
      MOVE.B    (A1)+,53(A0)
      MOVE.B    (A1)+,54(A0)
      BRA.S     L003D

APMIX_saut1_001E:
      MOVEQ     #0,D0 
      MOVE.B    (A1)+,D0
      MOVE.W    D0,34(A0) 
      MOVEA.L   24(A0),A1 
      ADDA.W    D0,A1 
      BRA.S     L003D

APMIX_saut2_002E:	  
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      CMP.B     57(A0),D1 
      BEQ.S     L0040 
      MOVE.B    D1,57(A0) 
      MOVE.W    42(A0),D0 
      OR.W      D0,(A5) 
      ;MOVE.W    D0,$DFF096
	  move.l				d0,dmacon_current_frame
	  
	  
      MOVEA.L   L0064(PC),A4
      MOVE.W    D1,D3 
      LSL.W     #3,D1 
      ADD.W     D3,D3 
      ADD.W     D3,D1 
      ADDA.W    D1,A4 
      MOVEA.L   0(A0),A3
      MOVEA.L   (A4)+,A2
      ADDA.L    L0065(PC),A2
      MOVE.L    A2,(A3) 						; ecriture pointeur debut sample
      MOVE.W    (A4)+,4(A3) 				; length sample
	  
	  
	  
      MOVEQ     #0,D1 
      MOVE.W    (A4)+,D1
      ADDA.L    D1,A2 
      MOVE.L    A2,16(A0) 
      MOVE.W    (A4),32(A0) 
L0040:MOVE.W    D7,36(A0) 
      MOVE.B    #1,49(A0) 
      ADDQ.W    #2,34(A0) 
      BRA       L003D
	  
APMIX_saut2_0086:
      ST        57(A0)
      MOVE.W    42(A0),D1 
      OR.W      D1,(A5) 
      ;MOVE.W    D1,$DFF096				; dmacon
	  ext.l		d1
	  move.l			d1,dmacon_current_frame
	  
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      MOVEA.L   L0064(PC),A4
      MOVE.W    D1,D3 
      LSL.W     #3,D1 
      ADD.W     D3,D3 
      ADD.W     D3,D1 
      ADDA.W    D1,A4 
      MOVEA.L   (A4)+,A2
      ADDA.L    L0065(PC),A2
      MOVEQ     #0,D0 
      MOVE.W    4(A2),D0
      MOVE.W    6(A2),D2
      LSL.W     #2,D2 
      MULU      #$18,D0 
      ADDQ.L    #8,A2 
      MOVEA.L   A2,A4 
      ADDA.L    D0,A2 
      ADDA.W    D2,A2 
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      MULU      #$18,D1 
      ADDA.L    D1,A4 
      MOVE.L    (A4)+,D1
      MOVE.L    (A4)+,D2
      ANDI.L    #$FFFFFFFE,D1 
      ANDI.L    #$FFFFFFFE,D2 
      SUB.L     D1,D2 
      LSR.L     #1,D2 
      ADD.L     A2,D1 
      MOVEA.L   0(A0),A3
      MOVE.L    D1,(A3) 						; DFF location
      MOVE.W    D2,4(A3)
 
	  
      MOVE.L    D1,16(A0) 
      PEA       (A2)
      MOVEA.L   D1,A2 
      MOVE.B    (A2)+,(A2)
      MOVEA.L   (A7)+,A2
      MOVEQ     #1,D1 
      MOVE.W    D1,32(A0) 
      MOVE.W    D7,36(A0) 
      MOVE.B    #1,49(A0) 
      ADDQ.W    #3,34(A0) 
      BRA       L003D

APMIX_saut2_0114:	  
      ST        57(A0)
      MOVE.W    42(A0),D1 
      OR.W      D1,(A5) 
      ;MOVE.W    D1,$DFF096
	  ext.l			d1
	  move.l				d1,dmacon_current_frame
	  
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      MOVEA.L   L0064(PC),A4
      MOVE.W    D1,D3 
      LSL.W     #3,D1 
      ADD.W     D3,D3 
      ADD.W     D3,D1 
      ADDA.W    D1,A4 
      MOVEA.L   0(A0),A3
      MOVEA.L   (A4)+,A2
      ADDA.L    L0065(PC),A2
      MOVE.L    A2,(A3) 					; location
      MOVE.W    (A4)+,4(A3) 			; length
	  
	  
	  
      MOVEQ     #0,D1 
      MOVE.W    (A4)+,D1
      ADDA.L    D1,A2 
      MOVE.L    A2,16(A0) 
      MOVE.W    (A4),32(A0) 
      MOVE.W    D7,36(A0) 
      MOVE.B    #1,49(A0) 
      ADDQ.W    #2,34(A0) 
      BRA       L003D
	  
APMIX_saut2_0166:	  
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      MOVEA.L   L0064(PC),A4
      MOVEA.L   0(A0),A3
      MOVE.W    D1,D3 
      LSL.W     #3,D1 
      ADD.W     D3,D3 
      ADD.W     D3,D1 
      ADDA.W    D1,A4 
      MOVEA.L   (A4)+,A2
      ADDA.L    L0065(PC),A2
      MOVE.L    A2,(A3) 					; location
      MOVE.W    (A4)+,4(A3) 			; length
	  
	  
      MOVEQ     #0,D1 
      MOVE.W    (A4)+,D1
      ADDA.L    D1,A2 
      MOVE.L    A2,16(A0) 
      MOVE.W    (A4),32(A0) 
      ADDQ.W    #2,34(A0) 
      BRA       L003D
	  
L0041:MOVE.B    D0,58(A0) 
      ADDQ.W    #1,34(A0) 
	  
L0042:
APMIX_saut2_01A6:
		TST.B     51(A0)
      BEQ.S     L0043 
      SUBQ.B    #1,51(A0) 
      BRA.S     L0048 
L0043:SUBQ.B    #1,49(A0) 
      BNE.S     L0048 
      MOVE.B    50(A0),49(A0) 
L0044:MOVEA.L   20(A0),A1 
      ADDA.W    36(A0),A1 
      MOVEQ     #0,D0 
      MOVE.B    (A1)+,D0
      CMP.W     #$E0,D0 
      BLT.S     L0047 
      SUBI.W    #$E0,D0 
      ADD.W     D0,D0 
      MOVE.W    L0045(PC,D0.W),D0 
      JMP       L0046(PC,D0.W)
L0045:
		dc.w			APMIX_2eme_saut_000A-L0046
		dc.w			APMIX_2eme_saut_0016-L0046
		dc.w			APMIX_2eme_saut_0016-L0046
		dc.w			APMIX_2eme_saut_0016-L0046
		dc.w			APMIX_2eme_saut_0016-L0046
		dc.w			APMIX_2eme_saut_0016-L0046
		dc.w			APMIX_2eme_saut_0016-L0046
		dc.w			APMIX_2eme_saut_0016-L0046
		dc.w			APMIX_2eme_saut_0000-L0046
; table de sauts 2 : 9 entrées
	;DC.B      $00,$0A,$00,$16,$00,$16,$00,$16 
      ;DC.B      $00,$16,$00,$16,$00,$16,$00,$16 
      ;DC.B      $00,$00 
APMIX_2eme_saut_0000:
L0046:
		MOVE.B    (A1),51(A0) 
      ADDQ.W    #2,36(A0) 
      BRA.S     L0042 

APMIX_2eme_saut_000A:	  
      MOVEQ     #0,D0 
      MOVE.B    (A1),D0 
      SUBQ.W    #5,D0 
      MOVE.W    D0,36(A0) 
      BRA.S     L0044 
	  
APMIX_2eme_saut_0016:	  
      BRA.S     L0048 
	  
L0047:MOVE.B    D0,60(A0) 
      ADDQ.W    #1,36(A0) 
L0048:MOVE.B    58(A0),D0 
      BMI.S     L0049 
      ADD.B     46(A0),D0 
      ADD.B     59(A0),D0 
L0049:ANDI.W    #$7F,D0 
      LEA       L0069(PC),A1
      ADD.W     D0,D0 
      MOVE.W    0(A1,D0.W),D0 
      TST.B     55(A0)
      BEQ.S     L004A 
      SUBQ.B    #1,55(A0) 
      BRA.S     L004E 
L004A:MOVEQ     #0,D4 
      MOVEQ     #0,D5 
      MOVE.B    61(A0),D6 
      MOVE.B    54(A0),D4 
      MOVE.B    53(A0),D5 
      BPL.S     L004B 
      ANDI.W    #$7F,D5 
      BCHG      #0,D6 
L004B:MOVE.W    D4,D3 
      ADD.W     D4,D4 
      MOVE.W    44(A0),D1 
      BTST      #0,D6 
      BNE.S     L004D 
      BTST      #5,D6 
      BNE.S     L004C 
      SUB.W     D5,D1 
      BPL.S     L004D 
      BSET      #5,D6 
      MOVEQ     #0,D1 
      BRA.S     L004D 
L004C:ADD.W     D5,D1 
      CMP.W     D4,D1 
      BLE.S     L004D 
      BCLR      #5,D6 
      MOVE.W    D4,D1 
L004D:MOVE.W    D1,44(A0) 
      SUB.W     D3,D1 
      ADD.W     D1,D0 
      MOVE.B    D6,61(A0) 
L004E:BTST      #5,47(A0) 
      BEQ.S     L0050 
      MOVEQ     #0,D1 
      MOVE.B    56(A0),D1 
      TST.B     D1
      BMI.S     L004F 
      MOVEQ     #$B,D3
      MOVE.L    12(A0),D2 
      LSL.L     D3,D1 
      ADD.L     D1,D2 
      MOVE.L    D2,12(A0) 
      SWAP      D2
      SUB.W     D2,D0 
      BRA.S     L0050 
L004F:NEG.B     D1
      MOVEQ     #$B,D3
      MOVE.L    12(A0),D2 
      LSL.L     D3,D1 
      ADD.L     D1,D2 
      MOVE.L    D2,12(A0) 
      SWAP      D2
      ADD.W     D2,D0 
L0050:SWAP      D0
      MOVEQ     #$64,D1 
      SUB.W     L0068(PC),D1
      MOVEQ     #0,D2 
      MOVE.B    60(A0),D2 
      MULU      D1,D2 
      DIVU      #$64,D2 
      MOVE.W    D2,D0 
      RTS 
L0051:DC.B      $01,$00,$00,$00,$00,$00,$00,$E1 
      DCB.W     8,0 
L0052:DCB.W     3,0 
L0053:DCB.W     2,0 
L0054:DC.B      $00,$00 
L0055:DCB.W     8,0 
L0056:DCB.W     8,0 
L0057:DCB.W     15,0
L0058:DCB.W     8,0 
L0059:DCB.W     8,0 
L005A:DCB.W     15,0
L005B:DCB.W     8,0 
L005C:DCB.W     8,0 
L005D:DCB.W     15,0
L005E:DC.B      $00,$A0,$00,$00,$00,$B0,$00,$03 
      DC.B      $00,$C0,$00,$06,$00,'@' 
L005F:DC.B      $00,$00 
L0060:DCB.W     2,0 
L0061:DCB.W     2,0 
L0062:DCB.W     2,0 
L0063:DCB.W     2,0 
L0064:DCB.W     2,0 
L0065:DCB.W     2,0 
L0066:DCB.W     2,0 
L0067:DCB.W     2,0 
L0068:DC.B      $00,$00 
; conversion notes vers period Amiga
L0069:DC.B      $06,$B0,$06,'P',$05,$F4,$05,$A0 
      DC.B      $05,'L',$05,$00,$04,$B8,$04,'t' 
      DC.B      $04,'4',$03,$F8,$03,$C0,$03,$8A 
      DC.B      $03,'X',$03,'(',$02,$FA,$02,$D0 
      DC.B      $02,$A6,$02,$80,$02,92,$02,":"					; 92=\
      DC.B      $02,$1A,$01,$FC,$01,$E0,$01,$C5 
      DC.B      $01,$AC,$01,$94,$01,'}',$01,'h' 
      DC.B      $01,'S',$01,'@',$01,'.',$01,$1D 
      DC.B      $01,$0D,$00,$FE,$00,$F0,$00,$E2 
      DC.B      $00,$D6,$00,$CA,$00,$BE,$00,$B4 
      DC.B      $00,$AA,$00,$A0,$00,$97,$00,$8F 
      DC.B      $00,$87,$00,$7F,$00,'x',$00,'q' 
      DC.B      $00,'q',$00,'q',$00,'q',$00,'q' 
      DC.B      $00,'q',$00,'q',$00,'q',$00,'q' 
      DC.B      $00,'q',$00,'q',$00,'q',$00,'q' 
      DC.B      $0D,'`',$0C,$A0,$0B,$E8,$0B,'@' 
      DC.B      $0A,$98,$0A,$00,$09,'p',$08,$E8 
      DC.B      $08,'h',$07,$F0,$07,$80,$07,$14 

; song 1	  
L006A:
			incbin		"song1.coso"
; songfile 2	  
L006B:
			incbin		"song2.coso"
L006C:
			incbin		"song3.coso"
L006D:
			incbin		"song4.coso"
L006E:
			incbin		"song5.coso"
L006F:
			incbin		"song6.coso"
L0070:
			incbin		"song7.coso"
	  
.dphrase
APMIX__debut_des_samples:
			incbin		"samples.sopmaxdig"

APMIX_entry_point_END: 


; liste des écritures dans les registres:
; tag : TO PAULA
;
; - dmacon_envoye
; - 


; exemple d'ecritures
;   ecriture 16 bits de 17ab0 en dff0a0			pris comme un repeat
;   ecriture 16 bits de 10 en dff0a4				length A
;   ecriture 16 bits de 17d en dff0a6				period A
;   ecriture 16 bits de 14 en dff0a8				volume A

;   ecriture 16 bits de 17af0 en dff0b0			pris comme un repeat
;   ecriture 16 bits de 10 en dff0b4				length B
;   ecriture 16 bits de 1c2 en dff0b6				period B
;   ecriture 16 bits de 14 en dff0b8				volume B

;   ecriture 16 bits de 0000000000000100 en dff096			coupe le son
;   ecriture 16 bits de 17b40 en dff0c0				prochain son , repeat
;   ecriture 16 bits de f1 en dff0c4					length C
;   ecriture 16 bits de 21a en dff0c6					note C
;   ecriture 16 bits de 28 en dff0c8					volume C
; => repeat



;   ecriture 16 bits de 1000000000000100 en dff096				prise en compte/forcage  du repeat précedent dans les registres internes, sur la voie concernée uniquement

; => repeat
;   ecriture 16 bits de 17ab0 en dff0a0				
;   ecriture 16 bits de 10 en dff0a4						length A
;   ecriture 16 bits de 17af0 en dff0b0
;   ecriture 16 bits de 10 en dff0b4						length B
;   ecriture 16 bits de 17b40 en dff0c0
;   ecriture 16 bits de 1 en dff0c4							length C



;   ----------------------------------489
;   ecriture 16 bits de 17d en dff0a6
;   ecriture 16 bits de 14 en dff0a8
;   ecriture 16 bits de 1c2 en dff0b6
;   ecriture 16 bits de 14 en dff0b8
;   ecriture 16 bits de 21a en dff0c6
;   ecriture 16 bits de 1e en dff0c8
