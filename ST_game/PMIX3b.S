explonr=11			;samplenr. des explo.ger.
	output	pmix.img

	opt	w-
header=1
demoflag=0
ste=1

a:
	ifne	header
	pea	main(pc)
	move.w	#38,-(sp)
	trap	#14
	addq.l	#6,sp
	illegal
	
	
main:
	ifne 	ste
********************************************
* LMC 1992 TONE CONTROLLER öBER		   * 
* MICROWIRE INTERFACE ANSTEUERN  (NUR STE) *
********************************************
MASTER_VOLUME	= 40	(0-40)
LEFT_CH_VOLUME	= 20	(0-20)	
RIGHT_CH_VOLUME	= 20	(0-20)
TREBLE		= 7	(0-12 / 6=Grundstellung)
BASS		= 8	(0-12 / 6=Grundstellung)

INIT_TONE_CONTROLLER:
	move.w	#$07ff,$ffff8924.w		; Set Microwire Mask

	move.w	#%011000000+MASTER_VOLUME,d0	; Set Master Volume
	bsr	.SEND_TO_MICROWIRE
	move.w	#%101000000+LEFT_CH_VOLUME,d0	; Set Left Channel Volume 
	bsr	.SEND_TO_MICROWIRE
	move.w	#%100000000+RIGHT_CH_VOLUME,d0	; Set Right Channel Volume
	bsr	.SEND_TO_MICROWIRE
	move.w	#%010000000+TREBLE,d0		; Set Treble
	bsr	.SEND_TO_MICROWIRE
	move.w	#%001000000+BASS,d0		; Set Bass
	bsr	.SEND_TO_MICROWIRE
	move.w	#%01,d0				; Set Mix
	bsr	.SEND_TO_MICROWIRE
	bra.s	.auûenrum	
.SEND_TO_MICROWIRE:
	or.w	#%10000000000,d0		; Select Tone Controller
	move.w	#1000,d7			; Microwire
.wait:	dbra	d7,.wait			; delay
	move.w	d0,$ffff8922.w			; Set MW Data Register
	rts
	endc
.auûenrum:
	move.b	#2,$ffff820a.w
	moveq	#$03,d0		; psg-digi=1,2=cent-digi,3=ste dma
	bsr	music+8	
	moveq	#1,d0
	bsr	music
	lea	musix32,a0
	bsr	music+16

loop:
	move.w	#37,-(sp)
	trap	#14
	addq.w	#2,sp

	move.w	#$2000,d0
wait:
	dbf	d0,wait

	move.w	$ffff8240.w,-(sp)
	move.w	digiflag,$ffff8240.w
	bsr	music+4
	move.w	(sp)+,$ffff8240.w
	pea	$600ff
	trap	#1
	addq.w	#4,sp
	move.l	d0,d1
	swap	d1
	tst.w	d1
	beq.s	.nstar
	cmp.w	#2,d1
	blt.s	.do
	cmp.w	#9,d1
	bge.s	.do
	move.w	d1,d0
	subq.w	#2,d0
	add.w	d0,d0
	addq.w	#1,d0
	ext.l	d0
 	bsr	music
	moveq	#0,d0
	bra.s	.nstar
.do:
	cmp.w	#"A",d0
	blt.s	.nstar
	cmp.w	#"a",d0
	blt.s	.allok
	sub.w	#$20,d0
.allok:
	sub.w	#"A",d0
	ext.l	d0
	bsr	music+20
	moveq	#0,d0
.nstar:
	tst.l	d0
	beq.s	loop
	
	moveq	#0,d0
	bsr	music
	bsr	music+12
	clr.w	-(sp)
	trap	#1
	endc


;---------------------
music:
	bra.w	songinit2
	bra.w	rout
	bra.w	startc
	bra.w	stopc
	bra.w	init_spch
	bra.w	play_spch
	dc.b	"IF YOU WANNA HACK DIZ MUSIC-> NOTE, THAT THERE ARE "
	dc.b 	"DIGI-DRUMS IN IT.... (PLEEZE WRITE IN THE MUSIC-HACK : "
	dc.b	34,"MUSIC BY JO HIPPLE",34,"  -TNX-  "
	even
init_spch:
	movem.l	d0-d1/d7/a0-a6,-(sp)
	lea	spchfile(pc),a1
	move.l	a0,(a1)
	lea	spconvflag(pc),a1
	tst.b	(a1)
	bne.s	nospconv
	move.l	spchfile(pc),a0
	lea	4(a0),a1
	move.w	(a1)+,d0
	move.w	d0,d7		;anzahl der samples
	subq.w	#1,d7		;als dbf !
	move.w	(a1)+,d1
	mulu	#24,d0
	move.l	a1,a2
	add.l	d0,a2		;zeiger auf samples
	lea	samplebase2(pc),a6
	move.l	a2,(a6)
convlp:
	move.l	(a1)+,d0	;stoffset
	move.l	(a1)+,d1	;endoffset
	lea	24-8(a1),a1	;zeigt jetzt auf sample nr 2
	move.l	a2,a3
	move.l	a2,a4
	add.l	d0,a3
	add.l	d1,a4
	bsr.s	do_convert
	dbf	d7,convlp
nospconv:
	movem.l	(sp)+,d0-d1/d7/a0-a6
	rts
do_convert:
	lea	steflag(pc),a5
	cmp.w	#2,(a5)
	beq	.arties
	lea	spconvflag(pc),a6
	st	(a6)
	tst.w	(a5)
	beq.s	.conv4bit

.conv8bit:
	move.b	(a3),d0
	eor.b	#$80,d0
	bne.s	.d0ok
	moveq	#1,d0
.d0ok:	
	move.b	d0,(a3)+
	cmp.l	a4,a3
	blt.s	.conv8bit
	sf	-(a4)
.arties:
	rts

.conv4bit:
	move.b	(a3),d0
	eor.b	#$80,d0
	lsr.b	#4,d0
	and.w	#$f,d0
	move.b	.dtab(pc,d0.w),(a3)+
	cmp.l	a4,a3
	blt.s	.conv4bit
	move.b	#$88,-(a4)	;ende-kennung setzen 
	rts
.dtab:
	dc.b	0,7,9,10,11,12,12
	dc.b	13,13,13,14,14,14,15,15,15

spconvflag:	dc.b	0
		even
spchfile:	dc.l	0


songinit2:
	movem.l d0-d7/a0-a6,-(sp)
	bsr	songinit
	movem.l (Sp)+,d0-d7/a0-a6
	rts

play_spch:		;in d0, nummer des samples
	movem.l	d0-d1/a0-a2,-(sp)
	lea	digiflag(pc),a1
	and.w	#$3f,d0
	cmp.w	#explonr,d0
	bne.s	.noexplonr
	tst.b	1(a1)
	bne.s	.exitplayspch
.noexplonr:
	mulu	#24,d0
	move.l	spchfile(pc),a0
	movem.l	8(a0,d0.w),d0-d1
	add.l	samplebase2(pc),d0
	add.l	samplebase2(pc),d1
	st	1(a1)		;spch	on
	lea	steflag(pc),a0
	cmp.w	#2,(a0)
	beq.s	.doste
	move.l	d0,a0
	move.l	a0,usp		;timer	setzen
        and.b	#%00000111,$fffffa1d.w
        or.b	#%10000,$fffffa1d.w	; Set Timer C Delay Mode 1:4
        move.b	#$65,$fffffa23.w	; Entspricht 6.08 Khz  
.exitplayspch:
	movem.l	(sp)+,d0-d1/a0-a2
	rts
.doste:
	lea	$ffff8900.w,a2		; DMA-Soundchip Basisadresse
	clr.w	(a2)			; DMA-Sound stoppen
	and.b	#$fe,d0
	and.b	#$fe,d1
	movep.w	d0,$5(a2)		; Set Start Address Low/Med Byte	
	swap	d0
 	move.w	d0,$2(a2)		; Set Start Address Hi Byte
	movep.w	d1,$11(a2)		; Set End Address Low/Med Byte	
	swap	d1
	move.w	d1,$e(a2)		; Set End Address Hi Byte
	move.w	#%10000000,$20(a2)	; Set Freq./Mode
	move.w	#1,(a2)			; Start Sample
	bra.s	.exitplayspch


songinit:
	ifeq	demoflag
	cmp.w	#3,d0			;1 und 2 songfile 1
	bge.s	.songfile1
	lea	songfile(pc),a0
	endc
	ifne	demoflag
	tst.w	d0
	beq.s	.nodo
	moveq	#1,d0
	lea	songfile4(pc),a0
.nodo:
	endc
	ifeq	demoflag
	bra.s	.doinit
.songfile1:
	cmp.w	#5,d0			;3 und 4 songfile 2
	bge.s	.songfile2
	subq.w	#2,d0
	lea	songfile2(pc),a0
	bra.s	.doinit
.songfile2:
	cmp.w	#7,d0			;5 und 6 songfile3
	bge.s	.songfile3
	subq.w	#4,d0
	lea	songfile3(pc),a0
	bra.s	.doinit
.songfile3:
	cmp.w	#9,d0
	bge.s	.songfile4
	lea	songfile4(pc),a0
	subq.w	#6,d0
	bra.s	.doinit
.songfile4:
	cmp.w	#11,d0
	bge.s	.songfile5
	lea	songfile5(pc),a0
	subq.w	#8,d0
	bra.s	.doinit
.songfile5:
	cmp.w	#13,d0
	bge.s	.songfile6
	lea	songfile6(pc),a0
	sub.w	#10,d0
	bra.s	.doinit
.songfile6:
	cmp.w	#15,d0
	bge.s	.songfile7
	lea	songfile7(pc),a0
	sub.w	#12,d0
	bra.s	.doinit
.songfile7:
	endc
.doinit:
	bsr.s	soundinit
	tst.w	d0
	beq.s	stopsong
usesong:
	subq.w	#1,d0
	move.l  songbase(pc),a1
	add.w	d0,d0		;mal 2
	move.w	d0,d1		;merken
	add.w	d0,d0		;jetzt mal 4
	add.w	d1,d0		;plus mal 2
	add.w	d0,a1		;= * 6 !!!
	move.w	(a1)+,d0
	move.w	(a1)+,d1
	lea	speedsyn+2(pc),a6
	move.w	(a1)+,(a6)
	bsr	init
	rts

stopsong:
	lea	speedsyn+4(pc),a0
	st	(a0)
	bra	rout

soundinit:
	lea	sogbase(pc),a6
	move.l	a0,(a6)

	move.l	4(a0),a1
	add.l	a0,a1
	lea	arpstart(pc),a6
	move.l	a1,(a6)

	move.l	8(a0),a1
	add.l	a0,a1
	lea	adsrstart(pc),a6
	move.l	a1,(a6)

	move.l	12(a0),a1
	add.l	a0,a1
	lea	seqbase(pc),a6
	move.l	a1,(a6)

	move.l	16(a0),a1
	add.l	a0,a1
	lea	esbe(pc),a6
	move.l	a1,(a6)

	move.l	20(a0),a1
	add.l	a0,a1
	lea	songbase(pc),a6
	move.l	a1,(a6)+

	move.l	24(a0),a1
	add.l	a0,a1
	move.l	a1,(a6)+ 

	lea	samples(pc),a1
	lea     samplebase(pc),a6
	move.l  a1,(a6)
 	lea	channel(pc),a6
adrchannel=*+2
	move.w	#2,(A6)
nosonginit:
	rts

;-----------------------------------------------------------------------------
;synthesizer(prg)
**************************
*   tfmx music-routine   *
*    by jochen hippel    *
**************************
rout:
	lea	steflag(pc),a0
	cmp.w	#2,(a0)
	bne.s	.noste
	lea	digiflag(pc),a0
	tst.b	1(a0)
	beq.s	.noste
	btst	#0,$ffff8901.w
	bne.s	.noste
	clr.w	(a0)
.noste:
	lea	ausblend(pc),a0
	tst.b	(a0)
	beq.s	noausblend
	subq.b	#1,1(a0)
	bpl.s	noausblend
	move.b	(a0),1(a0)
	addq.w	#1,2(a0)
	move.w	2(a0),d0
	cmp.w	#10,d0
	bne.s	aus1ok
	clr.l	(a0)
	lea	speedsyn+4(pc),a0
	st	(a0)
	bra.s	noausblend
aus1ok:
	lea     ausblendtab(pc),a0
	move.b  0(a0,d0.w),d0
	lea     voice1+$28(pc),a0
	lea     voice2+$28(pc),a1
	lea     voice3+$28(pc),a2
	move.b	d0,(a0)
	move.b	d0,(a1)
	move.b	d0,(a2)
noausblend:
	lea	ym2149(pc),a6
	lea	speedsyn(pc),a5
	tst.b	4(a5)
	beq.s	playit
	tst.b	5(a5)
	bne.s	noclear
	st	5(a5)
	moveq	#0,d0
	move.b	d0,8*4+2(a6)
	move.b	d0,9*4+2(a6)
	move.b	d0,10*4+2(a6)
	movem.l 7*4(a6),d0-d3
	movem.l d0-d3,$ffff8800.w
noclear:
	rts

playit:
	subq.w	#1,(a5)+
	bne.s	soundwork
	move.w	(a5),-(a5)
normalwork:
	moveq	#0,d5
	lea     voice1(pc),a0
	bsr     work
	lea     voice2(pc),a0
	bsr     work
	lea     voice3(pc),a0
	bsr     work
soundwork:
	lea	peesge(pc),a5
	lea	voice1(pc),a0
	bsr	swork
	move.w	d0,-(sp)
	move.b	(sp)+,1*4+2(a6)
	move.b	d0,0*4+2(a6)
	move.b	d1,8*4+2(a6)
	lea	voice2(pc),a0
	bsr	swork
	move.w	d0,-(sp)
	move.b	(sp)+,3*4+2(a6)
	move.b	d0,2*4+2(a6)
	move.b	d1,9*4+2(a6)
	lea     voice3(pc),a0
	bsr	swork
	move.w	d0,-(sp)
	move.b	(sp)+,5*4+2(a6)
	move.b	d0,4*4+2(a6)
	move.b	d1,10*4+2(a6)
;----------------------------
	move.w  4(a5),d0
	beq.s   nosfx
	move.w	d0,-(sp)
	lea	sfx(pc),a0
	bsr	swork
	move.l	$a(a0),a1
	add.l	$e(a0),a1
	cmp.b	#$e1,1(a1)
	bne.s	noendsx
	clr.w   4(a5)
noendsx:
	move.w  (sp)+,d7
	lea     voicetbl(pc),a1
	add.w   d7,d7
	add.w   d7,d7
	add.w   d7,a1
	moveq   #0,d6
	move.b  (a1)+,d6
	move.w  d0,-(sp)
	move.b  d0,0(a6,d6.w)
	move.b  (a1)+,d6
	move.b  (sp)+,0(a6,d6.w)
	move.b  (a1)+,d6
	move.b  d1,0(a6,d6.w)
nosfx:
	move.b	(a5)+,d7
	or.b	#%11000000,d7
	lea     digiflag(pc),a4
	tst.w   (a4)
	beq.s   nodigion
	or.b    #%00100100,d7
nodigion:
	move.b	d7,7*4+2(a6)
	move.b	(a5)+,6*4+2(a6)
	movem.l	(a6),d0-d7/a0-a2
	lea	digiflag(pc),a3
	tst.w   (a3)
	bne.s   digivoiceon
	movem.l	d0-d7/a0-a2,$ffff8840.w
endesyn:
	rts
digivoiceon:
	movem.l d0-d7/a0-a1,$ffff8840.w
	rts

work:
	subq.b	#1,$26(a0)
	bpl.s	endesyn
	move.b	$27(a0),$26(a0)
work2:
	move.l	$22(a0),a1
getnext:
	move.b	(a1)+,d0
	cmp.b	#$ff,d0
	bne.s	noendofseq
	move.l	$34(A0),a3
	move.l	(a0),a2
	add.l	4(a0),a2
	cmp.l	a3,a2
	bne.s	songnichtfertig
	move.l	d5,$4(a0)
	move.l	(a0),a2
songnichtfertig:
	moveq	#0,d1
	move.b	(A2),d1
	move.b	1(a2),$2c(a0)
	move.b	2(a2),$16(a0)
	move.b	3(a2),d0
	move.b	d0,d2
	and.w	#$f0,d2
	cmp.w	#$f0,d2
	bne.s	noausblend2
	move.b	d0,d2
	and.b	#$f,d2
	move.b	d2,$28(a0)
	bra.s	nospecial
noausblend2:
	cmp.b	#$e0,d2
	bne.s	nosetspeed
	move.b	d0,d2
	and.w	#$f,d2
	move.w	d2,2(a5)
;	bra.s	nospecial
nosetspeed:
nospecial:
	add.w	d1,d1
	add.w	d1,d1
	move.l	seqbase(pc),a3
	move.l	0(a3,d1.w),a3
	add.l	sogbase(pc),a3
	move.l	a3,$22(a0)
	add.l	#12,4(a0)
	bra	work2

noendofseq:
	cmp.b	#$fe,d0
	bne.s	nosetlength
	move.b	(a1),$27(a0)
	move.b	(a1)+,$26(a0)
	bra.w	getnext

nosetlength:
	cmp.b	#$fd,d0
	bne.s	nosetpp
	move.b	(a1),$27(a0)
	move.b	(a1)+,$26(a0)
	move.l	a1,$22(a0)
	rts
nosetpp:
	move.b	d0,$8(a0)
	move.b	(a1)+,d1
	move.b	d1,$9(a0)
	and.w	#%11100000,d1
	beq.s	nosetspecial
	move.b	(a1)+,$1f(a0)
nosetspecial:
	move.l	a1,$22(a0)
	move.l	d5,$38(a0)
;---------------------------------------
	tst.b	d0
	bmi.s	adsrnotsetnew
	move.b	$9(a0),d1
	move.b	d1,d0
	and.w	#$1f,d1
	add.b	$16(a0),d1
	move.l	adsrstart(pc),a2
	add.w	d1,d1
	add.w	d1,d1
	move.l	0(a2,d1.w),a2
	add.l	sogbase(pc),a2
	move.l	d5,$e(a0)
	move.b	(a2),$17(a0)
	move.b	(a2)+,$18(a0)
	moveq	#0,d1
	move.b	(a2)+,d1
	move.b	(a2)+,$1b(a0)
	move.b	#$40,$2e(a0)
	move.b	(a2)+,d2
	move.b	d2,$1c(a0)
	move.b	d2,$1d(a0)
	move.b	(a2)+,$1e(a0)
	move.l	a2,$a(a0)
	and.b	#$40,d0
	beq.s	noset40
	move.b	$1f(a0),d1
noset40:
	move.l	arpstart(pc),a2
	add.w	d1,d1
	add.w	d1,d1
	move.l	0(a2,d1.w),a2
	add.l	sogbase(pc),a2
	move.l	a2,$12(a0)
	move.l	d5,$30(a0)
	move.b	d5,$1a(a0)
	move.b	d5,$19(a0)
adsrnotsetnew:
keinenoteyeah:
	rts

swork:
 moveq   #0,d7
 move.b  d7,$20(a0)
arpwork3:
 tst.b   $1a(a0)
 beq.s   arpworkyeah
 subq.b  #1,$1a(a0)
 bra.w   adsrwork
arpworkyeah:
 move.l  $12(a0),a1
 add.l   $30(a0),a1
arpwork:
 cmp.b   #$e1,(a1)           ;ende ?
 beq    arpeggiotabende
 cmp.b   #$e0,(a1)           ;loop ?
 bne     keinloopaptab
 move.b  1(a1),d0
 and.l   #$3f,d0
 move.l  d0,$30(a0)
 move.l  $12(a0),a1
 add.l   d0,a1
keinloopaptab:
 cmp.b   #$e2,(a1)           ;waveon ?
 bne    nowaveon
 clr.l   $e(a0)
 move.b  #1,$17(a0)
 addq.l  #1,$30(a0)
 bra     arpworkyeah
nowaveon:
 cmp.b   #$e9,(a1)		;modu
 bne	 nomodu
 move.b  #$b,$ffff8800.w
 move.b  1(a1),$ffff8802.w
 move.b	 #$c,$ffff8800.w
 move.b  #0,$ffff8802.w
 move.b  #$d,$ffff8800.w
 move.b  #$a,$ffff8802.w
 addq.l  #2,$30(a0)
 bra	 arpworkyeah 

nomodu:
 cmp.b   #$e7,(a1)
 bne.s   nojump              ;jump ?
 lea    digiflag(pc),a4
 tst.b	1(a4)
 bne.s	.nostop
 clr.w	(a4)
 and.b  #%00000111,$fffffa1d.w
.nostop:
 addq.l #1,$30(a0)
 bra    arpworkyeah
nojump:
 cmp.b   #$e8,(a1)
 bne.s   nowaitarp           ;wait ?
 move.b  1(a1),$1a(a0)
 addq.l  #2,$30(a0)
 bra     arpwork3
nowaitarp:
 cmp.b   #$e4,(a1)           ;noise + rect
 bne.s   nonore
 move.b  d7,$2a(a0)
 move.b  1(a1),$20(a0)
 addq.l  #2,$30(a0)
 bra   arpwork2
nonore:
 cmp.b   #$e5,(a1)           ;noise ?
 bne.s   nonoise
 move.b  #1,$2a(a0)
 addq.l  #1,$30(a0)
 bra     arpwork3
nonoise:
 cmp.b   #$e6,(a1)           ;rect
 bne.s   norect
 move.b  #2,$2a(a0)
 addq.l  #1,$30(a0)
 bra   arpwork2
norect:
 cmp.b   #$e3,(a1)
 bne.s   nosetvib
 addq.l  #3,$30(a0)
 move.b  1(a1),$1b(a0)
 move.b  2(a1),$1c(a0)
; bra.s   arpwork2  
nosetvib:
	cmp.b	#$ea,(a1)			;drumvoice
	bne	nosetpor
	moveq	#0,d0
	moveq	#0,d1
	move.b	1(a1),d0
	add.w	d0,d0
	add.w	d0,d0
	add.w	d0,d0
	add.l	samplebase(pc),d0
	move.l	d0,a2
	lea     digiflag(pc),a4
	tst.b	1(a4)
	bne.s	.spchplay
	lea	steflag(pc),a1
	cmp.w	#2,(a1)
	beq.s	.doste
	cmp.w	#1,(a1)
	beq.s	.docent
	st	(a4)
.docent:
	move.w	(a2)+,a1
	add.l	samplebase(pc),a1
	move.l	a1,usp
        and.b	#%00000111,$fffffa1d.w
        or.b	#%10000,$fffffa1d.w	; Set Timer C Delay Mode 1:4
        move.b	#$65,$fffffa23.w	; Entspricht 6.08 Khz  
.spchplay:
	addq.l	#3,$30(a0)
	rts

.doste:
	movem.l	d0-d1/a2,-(sp)
	move.w	(a2),d0
	move.w	8(a2),d1
	lea	$ffff8900.w,a2		; DMA-Soundchip Basisadresse
	clr.w	(a2)			; DMA-Sound stoppen
	addq.w	#1,d0
	and.l	#$0000fffe,d0
	and.l	#$0000fffe,d1
	add.l	samplebase(pc),d0
	add.l	samplebase(pc),d1
	movep.w	d0,$5(a2)		; Set Start Address Low/Med Byte	
	swap	d0
	move.w	d0,$2(a2)		; Set Start Address Hi Byte

	movep.w	d1,$11(a2)		; Set End Address Low/Med Byte	
	swap	d1
	move.w	d1,$e(a2)		; Set End Address Hi Byte

	move.w	#%10000000,$20(a2)	; Set Freq./Mode
	move.w	#1,(a2)			; Start Sample
	addq.l	#3,$30(a0)
	movem.l	(sp)+,d0-d1/a2
	rts

nosetpor:
arpwork2:
 move.l  $12(a0),a1
 add.l   $30(a0),a1
 move.b  (a1),$2b(a0)
 addq.l  #1,$30(a0)
arpeggiotabende:

adsrwork:
 tst.b   $19(a0)
 beq.s   adsrwork05
 subq.b  #1,$19(a0)
 bra.s   nonewadsr
adsrwork05: 
 subq.b  #1,$17(a0)
 bne.s   nonewadsr
 move.b  $18(a0),$17(a0)
adsrwork2:
 move.l  $a(a0),a1
 add.l   $e(a0),a1
 move.b  (a1),d0
 cmp.b   #$e8,d0
 bne.s   nowaitadsr          ;wait ?
 addq.l  #2,$e(a0)
 move.b  1(a1),$19(a0)
 bra.s   adsrwork
nowaitadsr:
 cmp.b   #$e1,d0             ;ende ?
 beq.s   nonewadsr
 cmp.b   #$e0,d0             ;loop ?
 bne.s   noadsrloop
 move.b  1(a1),d0
 and.l   #$3f,d0
 subq.l  #5,d0
 move.l  d0,$e(a0)
 bra.s   adsrwork2
noadsrloop:
 move.b  (a1),$2d(a0)
 addq.l  #1,$e(a0)
nonewadsr:
 move.b  $2b(a0),d0
 bmi.s    notrelse
 add.b   $8(a0),d0
 add.b   $2c(a0),d0
notrelse:
 and.w   #$7f,d0
 lea     freqtab(pc),a1
 add.w   d0,d0
 move.w  d0,d1
 add.w   d0,a1
 move.w  (a1),d0
 move.b  $21(a0),d3
 move.b  $2a(a0),d2
 and.l   #$f,d2
 bne.s   nonore2
 bclr    d3,(A5)
 addq.w  #3,d3
 bclr    d3,(a5)
 bra.s   weitermache
nonore2:
 cmp.b   #1,d2
 bne.s   nonoise2
 bset    d3,(a5)
 addq.w  #3,d3
 bclr    d3,(a5)
 move.b  8(a0),$20(a0)
 move.b  $2b(a0),d4
 bpl.s   ndsyeah
 and.b   #$7f,d4
 move.b  d4,$20(A0)
 bra.s   weitermache
ndsyeah:
 add.b   d4,$20(a0)
 bra.s   weitermache
nonoise2:
 bclr    d3,(a5)
 addq.w  #3,d3
 bset    d3,(a5)
weitermache:
 tst.b   $20(a0)
 beq.s   keinrausche
 move.b  $20(a0),d3
 and.b   #$1f,d3
 eor.b   #$1f,d3
 move.b  d3,1(a5)
keinrausche:

;beim init $40 nach $2e(a0) schreiben

;2e = bit 5 richtung

 move.b  $2e(a0),d7
 tst.b   $1e(a0)
 beq.s   dovibrato
 subq.b  #1,$1e(a0)
 bra.s   b1f7e6
dovibrato:
 move.b  d1,d5
 move.b  $1c(a0),d4
 add.b   d4,d4
 move.b  $1d(a0),d1
 tst.b   d7
 bpl.s   b1f792
 btst    #$0,d7
 bne.s   b1f7c6
b1f792:
 btst    #$5,d7
 bne.s   b1f7b0
 sub.b   $1b(a0),d1
 bcc.s   b1f7c2
 bset    #$5,d7
 moveq   #$0,d1
 bra.s   b1f7c2
b1f7b0:
 add.b   $1b(a0),d1
 cmp.b   d4,d1
 bcs.s   b1f7c2
 bclr    #$5,d7
 move.b  d4,d1
b1f7c2:
 move.b  d1,$1d(a0)
b1f7c6:
 lsr.b   #$1,d4
 sub.b   d4,d1
 bcc.s   b1f7d2
 subi.w  #$100,d1
b1f7d2:
 addi.b  #$a0,d5
 bcs.s   b1f7e4
b1f7da:
 add.w   d1,d1
 addi.b  #$18,d5
 bcc.s   b1f7da
b1f7e4:
 add.w   d1,d0
b1f7e6:
 eori.b #$1,d7
 move.b d7,$2e(a0)

 btst    #$5,$9(a0)
 beq     noportamentoup
port:
 moveq   #0,d7
 move.w  d7,d1
 move.b  $1f(a0),d1
 ext.w   d1
 move.l  $38(a0),d2
 moveq   #12,d3
 asl.l   d3,d1
 add.l   d1,d2
 move.l  d2,$38(a0)
 swap    d2
 sub.w   d2,d0
noportamentoup:
 move.b  $2d(a0),d1
 sub.b   $28(a0),d1
 cmp.b	#$10,d1
 beq.s	adsrok
 lea	digiflag(pc),a0
 tst.b	1(a0)			;speech ?
 beq.s	.normalmus
 subq.b	 #1,d1			;hallo 5 marc rosocha
.normalmus:
 subq.b	 #1,d1			;hallo 5 marc rosocha
 bpl.s	 adsrok
 moveq	 #0,d1
adsrok:
 rts

init:
;input d0=from
;      d1=to
	lea	ausblend(pc),a0
	clr.l	(a0)
	and.b	#$0f,$fffffa1d.w
 	lea	digiflag(pc),a0
	clr.w	(a0)
	lea	speedsyn+4(pc),a0
	move.w	#$ff00,(a0)
	move.l	d0,d7
	mulu	#12,d7
	move.l	d1,d6
	addq.l	#1,d6
	mulu	#12,d6
	moveq	#2,d0
	lea	voice1(pc),a0
	lea	pause(pc),a1
	lea	psgtab(pc),a2
initlp:
	move.l	a1,$a(a0)
	clr.l	$e(a0)
	clr.b	$2d(a0)
	clr.b	$8(a0)
	clr.b	$9(a0)
	move.l	a1,$12(a0)
	clr.l	$30(a0)
	move.b	#$1,$17(a0)
	move.b	#$1,$18(a0)
	clr.b	$19(a0)
	clr.l	$1a(a0)
	clr.w	$1e(a0)
	clr.b	$20(a0)
	move.b	(a2),d3
	and.l	#$f,d3
	add.w	d3,d3
	add.w	d3,d3
	move.b	(a2)+,$21(a0)
	move.l	esbe(pc),(a0)
	move.l	esbe(pc),$34(a0)
	add.l	d6,$34(a0)
	add.l	d3,$34(a0)
	add.l	d7,(a0)
	add.l	d3,(a0)
	move.l	#12,4(a0)
	move.l	(A0),a3
	move.b	(a3),d1
	and.l	#$ff,d1
	add.w	d1,d1
	add.w	d1,d1
	move.l	seqbase(pc),a4
	move.l	0(a4,d1.w),a4
	add.l	sogbase(pc),a4
	move.l	a4,$22(a0)
	clr.l	$26(a0)
	move.b	#2,$2a(a0)
	move.b	1(a3),$2c(a0)
	clr.b	$2b(a0)
	move.b	2(a3),$16(a0)
	clr.b	$28(a0)
	move.b	3(a3),d1
	and.w	#$f0,d1
	cmp.w	#$f0,d1
	bne.s	noadsri
	move.b	3(a3),d1
	and.b	#$f,d1
	move.b	d1,$28(a0)
noadsri:
	clr.b	$2d(a0)
	clr.l	$38(a0)
	add.l	#voice2-voice1,a0
	dbf	d0,initlp
	lea	speedsyn(pc),a0
	move.w	#1,(a0)
	clr.w	4(a0)
	rts

sfxinit:
;input d0=adsrnumber
	move.w	sfxfreq(pc),d2
	move.w	channel(pc),d1
	tst.w	d2
	beq	arties
	lea	sfx(pc),a0
	lea	peesge(pc),a5
	move.b	d2,$8(a0)
	move.b	d1,$21(a0)
	clr.b	$16(a0)
	moveq	#0,d5

	and.w	#$ff,d0
	move.l	adsrstart(pc),a2
	add.w	d0,d0
	add.w	d0,d0
	move.l	0(a2,d0.w),a2
	add.l	sogbase(pc),a2
	move.l	d5,$e(a0)
	move.b	(a2),$17(a0)
	move.b	(a2)+,$18(a0)
	move.b	(a2)+,d0
	and.w	#$ff,d0
	move.b	(a2)+,$1b(a0)
	moveq	#0,d2
	move.b	#$40,$2e(a0)
	move.b	(a2)+,d2
	move.b	d2,$1c(a0)
	move.b	d2,$1d(a0)
	move.b	(a2)+,$1e(a0)
	move.l	a2,$a(a0)
	move.l	arpstart(pc),a2
	add.w	d0,d0
	add.w	d0,d0
	move.l	0(a2,d0.w),a2
	add.l	sogbase(pc),a2
	move.l	a2,$12(a0)
	move.l	d5,$30(a0)
	clr.b	$19(a0)
	clr.b	$1a(a0)
	clr.l	$38(a0)
	clr.b	$1f(a0)
	addq.w	#1,d1
	move.w	d1,4(a5)
arties:
	rts



startc:
	subq.w	#1,d0
	lea	steflag(pc),a0
	move.w	d0,(a0)
	move.w	sr,-(sp)
	move.w	#$2700,sr
	ifne	header
	lea	old_data(pc),a0
	move.l	$114.w,(a0)+
	move.b	$fffffa09.w,(a0)+
	move.b	$fffffa1d.w,(a0)+
	move.b	$fffffa15.w,(a0)+
	move.b	$fffffa17.w,(a0)+
	bclr	#3,$fffffa17.w		; Enter Auto EOI Modus
	endc 
        bset	#5,$fffffa09.w		; Enable
        bset	#5,$fffffa0d.w		; Timer
        bset	#5,$fffffa15.w		; C
	and.b	#%00000111,$fffffa1d.w	; Stop Timer C
	lea	timer_c(pc),a1
	move.w	steflag(pc),d7
	cmp.w	#1,d7
	bne.s	.nocent
	lea	timer_cent(pc),a1
.nocent:
	move.l	a1,$114.w
	move.l	#$0707ffff,$ffff8800.w
	move.b	#$e,$ffff8800.w
	move.b	$ffff8800.w,d0
	bset	#5,d0			;fÅr pro-sound strobe setzen !!
	move.b	d0,$ffff8802.w
	move.w	(sp)+,sr
	move.w	steflag(pc),d7
	cmp.w	#2,d7
	beq.s	.umrechnyeah
	lea	uflag(pc),a0
	tst.b	(a0)
	bne.s	.umrechnyeah
	st	(a0)
	lea	samples(pc),a0
	lea	$100(a0),a1
	move.l	a1,a2
	move.l	$fc(a0),d0
	sub.l	#$100,d0
	add.l	d0,a2
.convlp:
	move.b	(a1),d0
	cmp.b	#$ff,d0
	bne.s	.noff
	move.b	#$88,d0
	cmp.w	#1,d7
	bne.s	.nocent1
	moveq	#0,d0
.nocent1:
	bra.s	.write_down
.noff:
	eor.b	#$80,d0
	cmp.w	#1,d7
	bne.s	.nocent2
	tst.b 	d0
	bne.s	.write_down
	moveq	#1,d0
	bra.s	.write_down
.nocent2:	
	lsr.b	#4,d0
	and.w	#$f,d0
	move.b	.dtab(pc,d0.w),d0
.write_down:
	move.b	d0,(a1)+
	cmp.l	a2,a1
	ble.s	.convlp
.umrechnyeah:
	rts

.dtab:
	dc.b	0,7,9,10,11,12,12
	dc.b	13,13,13,14,14,14,15,15,15

stopc:
	move.w	sr,-(sp)
	move.w	#$2700,sr
	ifne	header
	lea	old_data(pc),a0	
	move.l	(a0)+,$114.w
	move.b	(a0)+,$fffffa09.w
	move.b	(a0)+,$fffffa1d.w
	move.b	(a0)+,$fffffa15.w
	move.b	(a0)+,$fffffa17.w
	move.b	#180,$fffffa23.w	
	endc
	ifeq	header
	and.b	#$f,$fffffa1d.w
	endc
	move.w	(sp)+,sr
	rts

timer_c:
	pea	(a0)
	move.l	usp,a0
	move.b	#$0a,$ffff8800.w
	move.b	(a0)+,$ffff8802.w
	move.l	a0,usp
	bpl.s	.nostoptimer
	lea	digiflag(pc),a0
	clr.w	(a0)
	and.b	#%00001111,$fffffa1d.w	; Stop Timer C
.nostoptimer:
	move.l	(sp)+,a0
	rte

timer_cent:
	pea	(a0)
	move.l	usp,a0
	move.b	#$0f,$ffff8800.w
	move.b	(a0)+,$ffff8802.w
	move.l	a0,usp
	bne.s	.nostoptimer
	lea	digiflag(pc),a0
	move.b	#$80,$ffff8802.w
	clr.w	(a0)
	and.b	#%00001111,$fffffa1d.w	; Stop Timer C
.nostoptimer:
	move.l	(sp)+,a0
	rte



digiflag:
	dc.b	0
	dc.b	0		;spch-flag
old_data:
	dc.l	0
	dc.b	0,0,0,0
	even
freqtab2:
 dc.l $400,$43C,$47D,$4C1,$50A,$556
 dc.l $5A8,$5FE,$659,$6BA,$720,$78D
 dc.l $800,$879,$8FA,$983,$A14,$AAD
 dc.l $B50,$BFC,$CB2,$D74,$E41,$F1A
 dc.l $1000,$10F3,$11F5,$1306,$1428,$155B
 dc.l $16A0,$17F9,$1965,$1AE8,$1C82,$1E34
 dc.l $2000,$21E7,$23EB,$260D,$2851,$2AB7
 dc.l $2D41,$2FF2,$32CB,$35D1,$3904,$3C68
 dc.l $4000,$43CE,$47D6,$4C1B,$50A2,$556E
 dc.l $5A82,$5FE4,$6597,$6BA2,$7208,$78D0
 dc.l $8000,$879C,$8FAC,$9837,$A145,$AADC
 dc.l $B504,$BFC8,$CB2F,$D744,$E411,$F1A1
 dc.l $10000,$10F38,$11F59,$1306F,$1428A,$155B8
 dc.l $16A09,$17F91,$1965F,$1AE89,$1C823,$1E343
 dc.l $20000,$21E71,$23EB3,$260DF,$28514,$2AB70
 dc.l $2D413,$2FF22,$32CBF,$35D13,$39047,$3C686
pause:
	dc.b	1,0,0,0,0,0,0,$e1
psgtab:
	dc.b	0,1,2,0
ym2149:
	dc.l	$00000000,$01010000,$02020000,$03030000
	dc.l	$04040000,$05050000,$06060000,$0707ffff
	dc.l	$08080000,$09090000,$0a0a0000

voicetbl:
	dc.b	0,0,0,0
	dc.b	2,6,34,0
	dc.b	10,14,38,0
	dc.b	18,22,42,0
speedsyn:
	dc.w 4,4
	dc.b $ff,00
ausblendtab:
	dc.b 0,1,2,3,4,5,6,7,8,9,10,11,15,15,15,15,15,15

voice1:	dcb.b 60,0
voice2:	dcb.b 60,0
voice3:	dcb.b 60,0
sfx:	dcb.b 60,0
esbe:	dc.l 0
seqbase:dc.l 0
peesge:	dc.w 0,0
sefx:	dc.w 0
sfxfreq:dc.w 0
channel:dc.w 0
ausblend:
	dc.l	0
songbase:
	dc.l	0,0
sogbase:dc.l	0
arpstart:
	dc.l 0
adsrstart:
	dc.l 0
samplebase:
        dc.l    0
samplebase2:
	dc.l	0
steflag:dc.w	0
uflag:	dc.w	0
freqtab:
	dc.b 014,238,014,023,013,077,012,142,011,217,011,047,010,142,009,247
	dc.b 009,103,008,224,008,097,007,232,007,119,007,011,006,166,006,071
	dc.b 005,236,005,151,005,071,004,251,004,179,004,112,004,048,003,244
	dc.b 003,187,003,133,003,083,003,035,002,246,002,203,002,163,002,125
	dc.b 002,089,002,056,002,024,001,250,001,221,001,194,001,169,001,145
	dc.b 001,123,001,101,001,081,001,062,001,044,001,028,001,012,000,253
	dc.b 000,238,000,225,000,212,000,200,000,189,000,178,000,168,000,159
	dc.b 000,150,000,142,000,134,000,126,000,119,000,112,000,106,000,100
	dc.b 000,094,000,089,000,084,000,079,000,075,000,071,000,067,000,063
	dc.b 000,059,000,056,000,053,000,050,000,047,000,044,000,042,000,039
	dc.b 000,037,000,035,000,033,000,031,000,029,000,028,000,026,000,025
	dc.b 000,023,000,022,000,021,000,019,000,018,000,017,000,016,000,015
;------------------------------------------------------------------------------
		ifeq	demoflag
songfile:	incbin	wod_lev0.scc
songfile2:	incbin	wod_lev1.scc
songfile3:	incbin	wod_lev2.scc
		endc
songfile4:	incbin	wod_lev3.scc
		ifeq	demoflag
songfile5:	incbin	wod_lev4.scc
songfile6:	incbin	wod_lev5.scc
songfile7:	incbin	wod_lev6.scc
		endc
		ifne	demoflag
		dcb.l	5939,"HIPP"
		endc

samples:	incbin	samples.img
	ifne	header
musix32:	incbin	speech.seq
	endc

b: