WOD_TFMX_OUTRO:
      BRA       L0000 
      BRA       L0005 
L0000:MOVEM.L   A0-A6/D0-D7,-(A7) 
      LEA       L004B(PC),A0
      MOVE.W    D0,-(A7)
      BSR       L0003 
      MOVE.W    (A7)+,D0
      BNE       L0001 
      LEA       L0032(PC),A6
      ST        (A6)
      BRA.S     L0002 
L0001:MOVEA.L   L0048(PC),A1
      SUBQ.L    #1,D0 
      ADD.W     D0,D0 
      MOVE.W    D0,D1 
      ADD.W     D1,D0 
      ADDA.W    D0,A1 
      MOVE.W    (A1)+,D0
      MOVE.W    (A1)+,D1
      LEA       L0031(PC),A6
      MOVE.W    (A1),(A6)+
      MOVE.W    (A1)+,(A6)+ 
      BSR       L0013 				; 1 replay lors de l'init
L0002:MOVEM.L   (A7)+,A0-A6/D0-D7 
      RTS 
	  
L0003:LEA       L0049(PC),A0
      TAS       (A0)
      BNE       L0004 
      ; BSET      #1,$BFE001
      LEA       L004B(PC),A0
      LEA       32(A0),A1 
      LEA       L0043(PC),A2
      MOVE.L    A1,(A2) 
      MOVE.W    4(A0),D0
      ADDQ.W    #1,D0 
      ASL.W     #6,D0 
      ADDA.W    D0,A1 
      LEA       L0044(PC),A2
      MOVE.L    A1,(A2) 
      MOVE.W    6(A0),D0
      ADDQ.W    #1,D0 
      ASL.W     #6,D0 
      ADDA.W    D0,A1 
      LEA       L0042(PC),A2
      MOVE.L    A1,(A2) 
      MOVEQ     #0,D0 
      MOVEQ     #0,D1 
      MOVE.W    8(A0),D0
      MOVE.W    12(A0),D1 
      LEA       L0040(PC),A2
      MOVE.W    D1,(A2) 
      ADDQ.W    #1,D0 
      MULU      D1,D0 
      ADDA.W    D0,A1 
      LEA       L0045(PC),A2
      MOVE.L    A1,(A2) 
      MOVE.W    10(A0),D0 
      ADDQ.W    #1,D0 
      MULU      #$C,D0
      ADDA.W    D0,A1 
      LEA       L0048(PC),A2
      MOVE.L    A1,(A2) 
      MOVE.W    16(A0),D0 
      ADDQ.W    #1,D0 
      MULU      #6,D0 
      ADDA.W    D0,A1 
      LEA       L0046(PC),A2
      MOVE.L    A1,(A2) 
      MOVE.W    18(A0),D0 
      MULU      #$1E,D0 
      ADDA.W    D0,A1 
      LEA       L0047(PC),A2
      MOVE.L    A1,(A2) 
L0004:RTS 





L0005:MOVEM.L   A0-A6/D0-D7,-(A7) 

		MOVEQ     #0,D7 

; repeat location = 0 pour simulation dmacon forcé
	  lea			Paula_custom,a6
	  move.l		d7,12(a6)				; voie A
	  move.l		d7,12+16(a6)			; voie B
	  move.l		d7,12+32(a6)			; voie C
	  move.l		d7,12+48(a6)			; voie D

      LEA       L0031(PC),A0
      TST.W     4(A0) 
      BEQ.S     L0006 
      MOVEQ     #0,D5 
      ;MOVE.W    #$F,$DFF096 
      MOVE.W    D5,channela+8
      MOVE.W    D5,channelb+8
      MOVE.W    D5,channelc+8
      MOVE.W    D5,channeld+8
      MOVEM.L   (A7)+,A0-A6/D0-D7 
      RTS 
L0006:MOVEQ     #0,D5 
      LEA       L0041(PC),A5
      SUBQ.W    #1,(A0)+
      BNE.S     L0007 
      MOVE.W    (A0),-(A0)
      MOVEQ     #6,D6 
      LEA       L0033(PC),A0
      BSR       L000B 
      LEA       L0036(PC),A0
      BSR       L000B 
      LEA       L0039(PC),A0
      BSR       L000B 
      LEA       L003C(PC),A0
      BSR       L000B 
L0007:MOVE.W    D5,(A5) 
      MOVEQ     #0,D7 
      ; LEA       $DFF000,A6
	  lea			Paula_custom-$A0,a6
      LEA       L0033(PC),A0
      BSR       L0015 
      MOVE.L    D0,166(A6)
      LEA       L0036(PC),A0
      BSR       L0015 
      MOVE.L    D0,182(A6)
      LEA       L0039(PC),A0
      BSR       L0015 
      MOVE.L    D0,198(A6)
      LEA       L003C(PC),A0
      BSR       L0015 
      MOVE.L    D0,214(A6)
      MOVE.W    (A5),D7 
      BEQ	     L0008 
      ORI.W     #$8000,D7 
      MOVEA.L   L0034(PC),A0
      MOVEA.L   L0037(PC),A1
      MOVEA.L   L003A(PC),A2
      MOVEA.L   L003D(PC),A3
      MOVE.W    L0035(PC),D0
      MOVE.W    L0038(PC),D1
      MOVE.W    L003B(PC),D2
      MOVE.W    L003E(PC),D3
      ;BSR.S     L0009 
      ;BSR.S     L0009 
      ;BSR.S     L0009 
      ;MOVE.W    D7,150(A6)
      ;BSR.S     L0009 

	move.l	d7,dmacon_current_frame

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
	  
	  
	  
	  
	  
      MOVE.L    A0,160(A6)
      MOVE.W    D0,164(A6)
      MOVE.L    A1,176(A6)
      MOVE.W    D1,180(A6)
      MOVE.L    A2,192(A6)
      MOVE.W    D2,196(A6)
      MOVE.L    A3,208(A6)
      MOVE.W    D3,212(A6)
L0008:MOVEM.L   (A7)+,A0-A6/D0-D7 
      RTS 
;L0009:MOVE.B    6(A6),D6
;L000A:CMP.B     6(A6),D6
;      BEQ.S     L000A 
;      RTS 
L000B:MOVE.W    L0040(PC),D7
      MOVEA.L   28(A0),A1 
      ADDA.W    60(A0),A1 
      MOVE.B    (A1),D0 
      ANDI.W    #$7F,D0 
      CMP.W     #1,D0 
      BEQ.S     L000C 
      CMP.W     60(A0),D7 
      BNE.S     L000F 
L000C:MOVEA.L   8(A0),A3
      MOVEA.L   4(A0),A2
      ADDA.W    58(A0),A2 
      CMPA.L    A3,A2 
      BNE.S     L000D 
      MOVE.W    D5,58(A0) 
      MOVEA.L   4(A0),A2
L000D:MOVEQ     #0,D1 
      MOVE.B    (A2),D1 
      MOVE.B    1(A2),79(A0)
      MOVE.B    2(A2),68(A0)
      CMPI.B    #$80,2(A2)
      BNE.S     L000E 
      LEA       L0032(PC),A2
      ST        (A2)
L000E:MOVE.W    D5,60(A0) 
      MULU      D7,D1 
      MOVEA.L   L0042(PC),A3
      ADDA.L    D1,A3 
      MOVE.L    A3,28(A0) 
      ADDI.W    #$C,58(A0)
      MOVEA.L   A3,A1 
L000F:MOVE.B    (A1)+,D0
      MOVE.B    D0,D1 
      ANDI.W    #$7F,D1 
      TST.W     D1
      BEQ       L0012 
      MOVE.L    D5,12(A0) 
      MOVE.B    D1,66(A0) 
      MOVEA.L   A1,A3 
      TST.W     60(A0)
      BNE.S     L0010 
      ADDA.W    D7,A3 
L0010:MOVE.B    -2(A3),76(A0) 
      MOVE.B    (A1),D1 
      MOVE.B    D1,67(A0) 
      TST.B     D0
      BMI.S     L0012 
      ANDI.W    #$1F,D1 
      ADD.B     68(A0),D1 
      MOVEA.L   L0044(PC),A2
      LSL.W     D6,D1 
      ADDA.W    D1,A2 
      MOVE.W    D5,56(A0) 
      MOVE.B    (A2),69(A0) 
      MOVE.B    (A2)+,70(A0)
      MOVEQ     #0,D1 
      MOVE.B    (A2)+,D1
      MOVE.B    (A2)+,73(A0)
      MOVEQ     #0,D0 
      MOVE.B    #$40,81(A0) 
      MOVE.B    (A2)+,D0
      MOVE.B    D0,74(A0) 
      MOVE.W    D0,64(A0) 
      MOVE.B    (A2)+,75(A0)
      MOVE.L    A2,20(A0) 
      MOVEA.L   L0043(PC),A2
      BTST      #6,67(A0) 
      BEQ.S     L0011 
      MOVE.B    76(A0),D1 
L0011:LSL.W     D6,D1 
      ADDA.W    D1,A2 
      MOVE.L    A2,24(A0) 
      MOVE.W    D5,54(A0) 
      MOVE.B    D5,72(A0) 
      MOVE.B    D5,71(A0) 
L0012:ADDQ.W    #2,60(A0) 
      RTS 
	  
L0013:
	MOVEQ     #0,D5 
	  lea			Paula_custom-$A0,a6
      ;LEA       $DFF000,A6
      ;MOVE.W    #$F,150(A6) 
      ;MOVE.W    #$780,154(A6) 
      MOVE.L    D0,D7 
      MULU      #$C,D7
      MOVE.L    D1,D6 
      ADDQ.L    #1,D6 
      MULU      #$C,D6
      MOVEQ     #3,D0 
      LEA       L0033(PC),A0
      LEA       L002F(PC),A1
      LEA       L003F(PC),A2
      LEA       L0030(PC),A5
L0014:MOVE.L    A1,20(A0) 
      MOVE.L    A1,24(A0) 
      MOVE.B    #1,69(A0) 
      MOVE.B    #1,70(A0) 
      SF        71(A0)
      MOVE.W    D5,56(A0) 
      SF        72(A0)
      SF        73(A0)
      SF        74(A0)
      SF        50(A0)
      MOVE.W    #0,64(A0) 
      SF        75(A0)
      SF        76(A0)
      ST        77(A0)
      MOVE.W    D5,60(A0) 
      SF        78(A0)
      SF        80(A0)
      MOVE.W    D5,54(A0) 
      MOVE.L    D5,12(A0) 
      MOVE.W    D5,52(A0) 
      MOVE.W    (A2)+,D1
      MOVE.W    (A2)+,D3
      DIVU      #3,D3 
      MOVEQ     #0,D4 
      BSET      D3,D4 
      MOVE.W    D4,62(A0) 
      MULU      #3,D3 
      ANDI.L    #$FF,D3 
      ANDI.L    #$FF,D1 
      ADD.L     A6,D1 
      MOVEA.L   D1,A4 
      MOVE.L    A4,(A4)+
      MOVE.W    #1,(A4)+
      MOVE.W    D5,(A4)+
      MOVE.W    D5,(A4)+
      MOVE.L    D1,0(A0)
      MOVE.L    L0045(PC),4(A0) 
      MOVE.L    L0045(PC),8(A0) 
      ADD.L     D6,8(A0)
      ADD.L     D3,8(A0)
      ADD.L     D7,4(A0)
      ADD.L     D3,4(A0)
      MOVE.W    #$C,58(A0)
      MOVEA.L   4(A0),A3
      MOVEQ     #0,D1 
      MOVE.B    (A3),D1 
      MOVE.W    L0040(PC),D2
      MULU      D1,D2 
      MOVEA.L   L0042(PC),A4
      ADDA.L    D2,A4 
      MOVE.L    A4,28(A0) 
      MOVE.B    1(A3),79(A0)
      MOVE.B    2(A3),68(A0)
      LEA       82(A0),A0 
      DBF       D0,L0014
      LEA       L0031(PC),A0
      MOVE.W    #1,(A0) 
      MOVE.W    D5,4(A0)
      RTS 
L0015:TST.B     72(A0)
      BEQ.S     L0016 
      SUBQ.B    #1,72(A0) 
      BRA       L0020 
L0016:MOVEA.L   24(A0),A1 
      ADDA.W    54(A0),A1 
L0017:MOVEQ     #0,D0 
      MOVE.B    (A1)+,D0
      CMP.W     #$E0,D0 
      BLT       L001C 
      SUBI.W    #$E0,D0 
      ADD.W     D0,D0 
      MOVE.W    L0018(PC,D0.W),D0 
      JMP       L0019(PC,D0.W)
L0018:
		dc.w		TFMX_saut1_0018-L0019		
		dc.w		TFMX_saut1_027A-L0019		
		dc.w		TFMX_saut1_01D0-L0019		
		dc.w		TFMX_saut1_000A-L0019		
		dc.w		TFMX_saut1_022E-L0019		
		dc.w		TFMX_saut1_0120-L0019		
		dc.w		TFMX_saut1_01A4-L0019		
		dc.w		TFMX_saut1_0028-L0019		
		dc.w		TFMX_saut1_0000-L0019		;
		dc.w		TFMX_saut1_008C-L0019		 



;DC.B      $00,$18,$02,'z',$01,$D0,$00,$0A 
 ;     DC.B      $02,'.',$01,' ',$01,$A4,$00,'(' 
 ;     DC.B      $00,$00,$00,$8C 
L0019:

TFMX_saut1_0000:
	MOVE.B    (A1)+,72(A0)
      ADDQ.W    #2,54(A0) 
      BRA.S     L0015 

TFMX_saut1_000A:	  
      ADDQ.W    #3,54(A0) 
      MOVE.B    (A1)+,73(A0)
      MOVE.B    (A1)+,74(A0)
      BRA.S     L0017 

TFMX_saut1_0018:
      MOVEQ     #0,D0 
      MOVE.B    (A1)+,D0
      MOVE.W    D0,54(A0) 
      MOVEA.L   24(A0),A1 
      ADDA.W    D0,A1 
      BRA.S     L0017 

TFMX_saut1_0028:	  
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      CMP.B     77(A0),D1 
      BEQ.S     L001A 
      MOVE.B    D1,77(A0) 
      MOVE.W    62(A0),D0 
      OR.W      D0,(A5) 
      ;MOVE.W    D0,$DFF096
      MOVEA.L   L0046(PC),A4
      MOVE.W    D1,D3 
      LSL.W     #5,D1 
      ADD.W     D3,D3 
      SUB.W     D3,D1 
      ADDA.W    D1,A4 
      MOVEA.L   0(A0),A3
      MOVEA.L   18(A4),A2 
      ADDA.L    L0047(PC),A2
      MOVE.L    A2,(A3) 
      MOVEQ     #0,D1 
      MOVE.W    26(A4),D1 
      ADDA.L    D1,A2 
      MOVE.L    A2,16(A0) 
      MOVE.W    22(A4),4(A3)
      MOVE.W    28(A4),52(A0) 
L001A:MOVE.W    D7,56(A0) 
      MOVE.B    #1,69(A0) 
      ADDQ.W    #2,54(A0) 
      SF        50(A0)
      BRA       L0017 
	  
TFMX_saut1_008C:
      ST        77(A0)
      MOVE.W    62(A0),D1 
      OR.W      D1,(A5) 
      ;MOVE.W    D1,$DFF096
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      MOVEA.L   L0046(PC),A4
      MOVE.W    D1,D3 
      LSL.W     #5,D1 
      ADD.W     D3,D3 
      SUB.W     D3,D1 
      ADDA.W    D1,A4 
      MOVEA.L   18(A4),A2 
      ADDA.L    L0047(PC),A2
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
      MOVE.L    D1,(A3) 
      MOVE.W    D2,4(A3)
      MOVE.L    D1,16(A0) 
      PEA       (A2)
      MOVEA.L   D1,A2 
      MOVE.B    (A2)+,(A2)
      MOVEA.L   (A7)+,A2
      MOVEQ     #1,D1 
      MOVE.W    D1,52(A0) 
      MOVE.W    D7,56(A0) 
      MOVE.B    #1,69(A0) 
      ADDQ.W    #3,54(A0) 
      SF        50(A0)
      BRA       L0017 

TFMX_saut1_0120:	  
      MOVE.W    62(A0),D1 
      OR.W      D1,(A5) 
      ;MOVE.W    D1,$DFF096
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      MOVEA.L   L0046(PC),A4
      MOVE.W    D1,D3 
      LSL.W     #5,D1 
      ADD.W     D3,D3 
      SUB.W     D3,D1 
      ADDA.W    D1,A4 
      MOVEA.L   18(A4),A2 
      MOVE.L    A2,32(A0) 
      MOVEQ     #0,D0 
      MOVE.W    22(A4),D0 
      MOVE.W    D0,D1 
      ADD.L     D0,D0 
      ADDA.L    D0,A2 
      MOVE.L    A2,36(A0) 
      MOVE.B    (A1)+,-(A7) 
      MOVE.W    (A7)+,D0
      MOVE.B    (A1)+,D0
      CMP.W     #$FFFF,D0 
      BNE.S     L001B 
      MOVE.W    D1,D0 
L001B:MOVE.W    D0,40(A0) 
      MOVE.B    (A1)+,-(A7) 
      MOVE.W    (A7)+,D0
      MOVE.B    (A1)+,D0
      MOVE.W    D0,44(A0) 
      MOVE.B    (A1)+,-(A7) 
      MOVE.W    (A7)+,D0
      MOVE.B    (A1)+,D0
      MOVE.W    D0,42(A0) 
      SF        48(A0)
      MOVE.B    (A1)+,49(A0)
      SF        51(A0)
      SF        46(A0)
      ST        50(A0)
      MOVE.W    D7,56(A0) 
      MOVE.B    #1,69(A0) 
      ADDI.W    #9,54(A0) 
      BRA       L0017 
	  
TFMX_saut1_01A4:	  
      MOVE.B    (A1)+,-(A7) 
      MOVE.W    (A7)+,D0
      MOVE.B    (A1)+,D0
      MOVE.W    D0,44(A0) 
      MOVE.B    (A1)+,-(A7) 
      MOVE.W    (A7)+,D0
      MOVE.B    (A1)+,D0
      MOVE.W    D0,42(A0) 
      SF        48(A0)
      MOVE.B    (A1)+,49(A0)
      SF        46(A0)
      SF        51(A0)
      ADDQ.W    #6,54(A0) 
      BRA       L0017 

TFMX_saut1_01D0:
      ST        77(A0)
      MOVE.W    62(A0),D1 
      OR.W      D1,(A5) 
      ;MOVE.W    D1,$DFF096
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      MOVEA.L   L0046(PC),A4
      MOVE.W    D1,D3 
      LSL.W     #5,D1 
      ADD.W     D3,D3 
      SUB.W     D3,D1 
      ADDA.W    D1,A4 
      MOVEA.L   0(A0),A3
      MOVEA.L   18(A4),A2 
      ADDA.L    L0047(PC),A2
      MOVE.L    A2,(A3) 
      MOVEQ     #0,D1 
      MOVE.W    26(A4),D1 
      ADDA.L    D1,A2 
      MOVE.L    A2,16(A0) 
      MOVE.W    22(A4),4(A3)
      MOVE.W    28(A4),52(A0) 
      MOVE.W    D7,56(A0) 
      MOVE.B    #1,69(A0) 
      ADDQ.W    #2,54(A0) 
      SF        50(A0)
      BRA       L0017 

TFMX_saut1_022E:	  
      MOVEQ     #0,D1 
      MOVE.B    (A1)+,D1
      MOVEA.L   L0046(PC),A4
      MOVE.W    D1,D3 
      LSL.W     #5,D1 
      ADD.W     D3,D3 
      SUB.W     D3,D1 
      ADDA.W    D1,A4 
      MOVEA.L   0(A0),A3
      MOVEA.L   18(A4),A2 
      ADDA.L    L0047(PC),A2
      MOVE.L    A2,(A3) 
      MOVEQ     #0,D1 
      MOVE.W    26(A4),D1 
      ADDA.L    D1,A2 
      MOVE.L    A2,16(A0) 
      MOVE.W    22(A4),4(A3)
      MOVE.W    28(A4),52(A0) 
      ADDQ.W    #2,54(A0) 
      SF        50(A0)
      BRA       L0017 

L001C:MOVE.B    D0,78(A0) 
      ADDQ.W    #1,54(A0) 

TFMX_saut1_027A:	  
      TST.B     50(A0)
      BEQ       L0020 
      TST.B     51(A0)
      BNE       L0020 
      SUBQ.B    #1,48(A0) 
      BPL       L0020 
      MOVE.B    49(A0),48(A0) 
      MOVEA.L   32(A0),A1 
      MOVEA.L   36(A0),A2 
      MOVEQ     #0,D0 
      MOVE.W    40(A0),D0 
      MOVE.W    42(A0),D1 
      MOVE.W    44(A0),D2 
      TST.B     46(A0)
      BNE.S     L001D 
      ST        46(A0)
      BRA.S     L001F 
L001D:EXT.L     D1
      ADD.L     D1,D0 
      BPL.S     L001E 
      ST        51(A0)
      SUB.L     D1,D0 
      BRA.S     L001F 
L001E:MOVEA.L   A1,A3 
      MOVE.L    D0,D3 
      ADD.L     D3,D3 
      ADDA.L    D3,A3 
      MOVEQ     #0,D3 
      MOVE.W    D2,D3 
      ADD.L     D3,D3 
      ADDA.L    D3,A3 
      CMPA.L    A2,A3 
      BLE.S     L001F 
      ST        51(A0)
      SUB.L     D1,D0 
L001F:MOVE.W    D0,40(A0) 
      ADDA.L    L0047(PC),A1
      ADD.L     D0,D0 
      ADDA.L    D0,A1 
      MOVE.W    D2,52(A0) 
      MOVE.L    A1,16(A0) 
      MOVEA.L   0(A0),A2
      MOVE.L    A1,(A2)+
      MOVE.W    D2,(A2)+
L0020:TST.B     71(A0)
      BEQ.S     L0021 
      SUBQ.B    #1,71(A0) 
      BRA.S     L0026 
L0021:SUBQ.B    #1,69(A0) 
      BNE.S     L0026 
      MOVE.B    70(A0),69(A0) 
L0022:MOVEA.L   20(A0),A1 
      ADDA.W    56(A0),A1 
      MOVEQ     #0,D0 
      MOVE.B    (A1)+,D0
      CMP.W     #$E0,D0 
      BLT.S     L0025 
      SUBI.W    #$E0,D0 
      ADD.W     D0,D0 
      MOVE.W    L0023(PC,D0.W),D0 
      JMP       L0024(PC,D0.W)
L0023:
		dc.w		TFMX_saut2_000A-L0024
		dc.w		TFMX_saut2_0016-L0024
		dc.w		TFMX_saut2_0016-L0024
		dc.w		TFMX_saut2_0016-L0024
		dc.w		TFMX_saut2_0016-L0024
		dc.w		TFMX_saut2_0016-L0024
		dc.w		TFMX_saut2_0016-L0024
		dc.w		TFMX_saut2_0016-L0024
		dc.w		TFMX_saut2_0000-L0024
;DC.B      $00,$0A,$00,$16,$00,$16,$00,$16 
 ;     DC.B      $00,$16,$00,$16,$00,$16,$00,$16 
  ;    DC.B      $00,$00 
L0024:
TFMX_saut2_0000:
	MOVE.B    (A1),71(A0) 
      ADDQ.W    #2,56(A0) 
      BRA.S     L0020 

TFMX_saut2_000A:	    
      MOVEQ     #0,D0 
      MOVE.B    (A1),D0 
      SUBQ.W    #5,D0 
      MOVE.W    D0,56(A0) 
      BRA.S     L0022 

TFMX_saut2_0016:	  
      BRA.S     L0026 
L0025:MOVE.B    D0,80(A0) 
      ADDQ.W    #1,56(A0) 
L0026:MOVE.B    78(A0),D0 
      BMI.S     L0027 
      ADD.B     66(A0),D0 
      ADD.B     79(A0),D0 
L0027:ANDI.W    #$7F,D0 
      LEA       L004A(PC),A1
      ADD.W     D0,D0 
      MOVE.W    0(A1,D0.W),D0 
      TST.B     75(A0)
      BEQ.S     L0028 
      SUBQ.B    #1,75(A0) 
      BRA.S     L002C 
L0028:MOVEQ     #0,D4 
      MOVEQ     #0,D5 
      MOVE.B    81(A0),D6 
      MOVE.B    74(A0),D4 
      MOVE.B    73(A0),D5 
      BPL.S     L0029 
      ANDI.W    #$7F,D5 
      BCHG      #0,D6 
L0029:MOVE.W    D4,D3 
      ADD.W     D4,D4 
      MOVE.W    64(A0),D1 
      BTST      #0,D6 
      BNE.S     L002B 
      BTST      #5,D6 
      BNE.S     L002A 
      SUB.W     D5,D1 
      BPL.S     L002B 
      BSET      #5,D6 
      MOVEQ     #0,D1 
      BRA.S     L002B 
L002A:ADD.W     D5,D1 
      CMP.W     D4,D1 
      BLE.S     L002B 
      BCLR      #5,D6 
      MOVE.W    D4,D1 
L002B:MOVE.W    D1,64(A0) 
      SUB.W     D3,D1 
      ADD.W     D1,D0 
      MOVE.B    D6,81(A0) 
L002C:BTST      #5,67(A0) 
      BEQ.S     L002E 
      MOVEQ     #0,D1 
      MOVE.B    76(A0),D1 
      TST.B     D1
      BMI.S     L002D 
      MOVEQ     #$B,D3
      MOVE.L    12(A0),D2 
      LSL.L     D3,D1 
      ADD.L     D1,D2 
      MOVE.L    D2,12(A0) 
      SWAP      D2
      SUB.W     D2,D0 
      BRA.S     L002E 
L002D:NEG.B     D1
      MOVEQ     #$B,D3
      MOVE.L    12(A0),D2 
      LSL.L     D3,D1 
      ADD.L     D1,D2 
      MOVE.L    D2,12(A0) 
      SWAP      D2
      ADD.W     D2,D0 
L002E:SWAP      D0
      MOVE.W    D7,D0 
      MOVE.B    80(A0),D0 
      RTS 
; $000197C0	   sur Amiga
L002F:DC.B      $01,$00,$00,$00,$00,$00,$00,$E1 
      DCB.W     8,0 
L0030:DCB.W     3,0 
L0031:DCB.W     2,0 
L0032:DC.B      $00,$00 
L0033:DCB.W     8,0 
L0034:DCB.W     18,0
L0035:DCB.W     15,0
L0036:DCB.W     8,0 
L0037:DCB.W     18,0
L0038:DCB.W     15,0
L0039:DCB.W     8,0 
L003A:DCB.W     18,0
L003B:DCB.W     15,0
L003C:DCB.W     8,0 
L003D:DCB.W     18,0
L003E:DCB.W     15,0
L003F:DC.B      $00,$A0,$00,$00,$00,$B0,$00,$03 
      DC.B      $00,$C0,$00,$06,$00,$D0,$00,$09 
L0040:DC.B      $00,'@' 
L0041:DC.B      $00,$00 
L0042:DC.B      $00,$01,$A1,'N' 
L0043:DC.B      $00,$01,$9A,$0E 
L0044:DC.B      $00,$01,$9C,$8E 
L0045:DC.B      $00,$01,$AD,$8E 
L0046:DC.B      $00,$01,$B1,'0' 
L0047:DCB.W     2,0 
L0048:DC.B      $00,$01,$B1,$1E 
L0049:DC.B      $00,$00 			; $80,0
L004A:DC.B      $06,$B0,$06,'P',$05,$F4,$05,$A0 
      DC.B      $05,'L',$05,$00,$04,$B8,$04,'t' 
      DC.B      $04,'4',$03,$F8,$03,$C0,$03,$8A 
      DC.B      $03,'X',$03,'(',$02,$FA,$02,$D0 
      DC.B      $02,$A6,$02,$80,$02,$5C,$02,':' 
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


L004B:
		incbin		"WoD_outro.tfmx"
		.phrase