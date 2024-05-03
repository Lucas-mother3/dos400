	PAGE	,132								;AN000;
	TITLE	DOS - GRAPHICS Command  -	Command line parsing module	;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;					;AN000;
;; DOS - GRAPHICS Command
;; (C) Copyright 1988 Microsoft
;;										;AN000;
;; File Name:  GRPARMS.ASM							;AN000;
;; ----------									;AN000;
;;										;AN000;
;; Description: 								;AN000;
;; ------------ 								;AN000;
;;										;AN000;
;;	 This file contains modules for parsing the GRAPHICS.COM		;AN000;
;;	 command line; using the DOS PARSER.					;AN000;
;;										;AN000;
;;										;AN000;
;; Documentation Reference:							;AN000;
;; ------------------------							;AN000;
;;	 OASIS High Level Design						;AN000;
;;	 OASIS GRAPHICS I1 Overview						;AN000;
;;	 DOS 3.3 Message Retriever Interface Supplement. 			;AN000;
;;	 TUPPER I0 Document - PARSER HIGH LEVEL DESIGN REVIEW			;AN000;
;;										;AN000;
;; Procedures Contained in This File:						;AN000;
;; ----------------------------------						;AN000;
;;	 PARSE_PARMS	  - Parse the command line				;AN000;
;;	 GET_R		  - Get /R						;AN000;
;;	 GET_B		  - Get /B						;AN000;
;;	 GET_LCD	  - Get /LCD						;AN000;
;;	 GET_PRINTBOX	  - Get /PRINTBOX					;AN000;
;;	 GET_PROFILE	  - Get the profile path and file name			;AN000;
;;	 GET_TYPE	  - Get the printer type				;AN000;
;;										;AN000;
;; Include Files Required:							;AN000;
;; -----------------------							;AN000;
;;	 GRINST.EXT  - Externals for installation modules			;AN000;
;;	 GRPARSE.EXT - Externals for the DOS parser code			;AN000;
;;	 GRSHAR.STR  - Shared Data Area Structure				;AN000;
;;	 GRMSG.EQU   - Equates for GRAPHICS.COM error messages			;AN000;
;;	 STRUC.INC   - Macros for using structured assembly language		;AN000;
;;										;AN000;
;; External Procedure References:						;AN000;
;; ------------------------------						;AN000;
;;	 FROM FILE  GRINST.ASM: 						;AN000;
;;	      GRAPHICS_INSTALL - Main module for the installation of GRAPHICS	;AN000;
;;	 SYSPARSE - DOS system parser						;AN000;
;;	 SYSDISPMSG - DOS message retriever					;AN000;
;;										;AN000;
;; Linkage Instructions:							;AN000;
;; -------------------- 							;AN000;
;;	 Refer to GRAPHICS.ASM							;AN000;
;;										;AN000;
;; Change History:								;AN000;
;; ---------------								;AN000;
;;										;AN000;
;;										;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;					;AN000;
CODE	SEGMENT PUBLIC 'CODE'                                                   ;AN000;
	ASSUME	CS:CODE,DS:CODE 						;AN000;
PARSE_PARMS PROC NEAR								;AN000;
	jmp	PARSE_PARMS_START						;AN000;
PUBLIC PARSE_PARMS								;AN000;
.XLIST										;AN000;
INCLUDE GRMSG.EQU		; Include GRAPHICS error messages equates	;AN000;
INCLUDE GRSHAR.STR		; Include the Shared data area structure	;AN000;
INCLUDE GRINST.EXT		; Include externals for the installation module ;AN000;
INCLUDE GRPARSE.EXT		; Include externals for the DOS parse code	;AN000;
INCLUDE STRUC.INC		; Include macros for using STRUCTURES		;AN000;
.LIST										;AN000;
										;AN000;
PAGE										;AN000;
;===============================================================================;AN000;
;										;AN000;
; PARSE_PARMS : PARSE THE COMMAND LINE PARAMETERS.				;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
;										;AN000;
;	INPUT:	DS,ES		= SEGMENT CONTAINING THE PROGRAM PREFIX SEGMENT ;AN000;(PSP)
;										;AN000;
;	OUTPUT: SWITCHES	= A bit mask in the shared data area indicating ;AN000;
;				  which command line switches are set.		;AN000;
;		PROFILE_PATH	= The profile file name and path (ASCIIZ string);AN000;
;		PRINTBOX_ID_PTR = Offset of the printbox id (ASCIIZ string)	;AN000;
;		PRINTER_TYPE_PARM = printer type (ASCIIZ string)		;AN000;
;		CARRY FLAG IS SET if an error occurred				;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
;										;AN000;
; DESCRIPTION: Call the DOS parser to parse the command line parameters 	;AN000;
; of the GRAPHICS  command line which is obtained from the PSP (Program Segment ;AN000;
; Prefix).									;AN000;
;										;AN000;
; The format of the command line is:						;AN000;
;										;AN000;
;										;AN000;
;	GRAPHICS  {prt_type {profile}}	 {/R}  {/B}  {[/LCD | /PRINTBOX:id]}	;AN000;
;										;AN000;
;	(All arguments are optional, /PRINTBOX can be spelled /PB.)		;AN000;
;										;AN000;
; If no printer type is specified then, a null pointer is returned.		;AN000;
; If no profile name is supplied then, a null string is returned.		;AN000;
; If "/LCD" is specified then, a pointer to the printbox id: "LCD" is returned. ;AN000;
;										;AN000;
;										;AN000;
; LOGIC:									;AN000;
; Set addressibility to the command line parameters in the PSP			;AN000;
; CALL SYSPARSE       ; Call the system parser					;AN000;
; While not (End Of Line) AND no error						;AN000;
;   IF argument is the profile name						;AN000;
;   THEN Get the profile name							;AN000;
;   IF argument is the printbox switch						;AN000;
;   THEN Get the printbox id							;AN000;
;   IF argument is a /r 							;AN000;
;   THEN Get /r 								;AN000;
;   IF argument is /b								;AN000;
;   THEN Get /b 								;AN000;
;   IF argument /lcd								;AN000;
;   THEN Get /lcd								;AN000;
;   CALL SYSPARSE								;AN000;
; If error									;AN000;
; Then display the appropriate error message					;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
; BIT MASK INDICATING THE COMMAND LINE SWITCHES PARSED SO FAR:			;AN000;
;-------------------------------------------------------------------------------;AN000;
SWITCH_PARSED DB   0								;AN000;
GOT_R	      EQU  1			; Found /R				;AN000;
GOT_B	      EQU  2			; Found /B				;AN000;
GOT_LCD       EQU  4			; Found /LCD				;AN000;
GOT_PRINTBOX  EQU  8			; Found /PB:id or /PRINTBOX:id		;AN000;
										;AN000;
;===============================================================================;AN000;
;										;AN000;
; CONTROL BLOCK DEFINITIONS FOR THE PARSER:					;AN000;
;										;AN000;
;===============================================================================;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; PARMS INPUT BLOCK								;AN000;
;-------------------------------------------------------------------------------;AN000;
PARMS LABEL WORD								;AN000;
	DW	PARMSX			; Offset of parms extension block	;AN000;
	DB	0			; No delimiters to define		;AN000;
					;  or end of line markers.		;AN000;
										;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; PARMS EXTENSION BLOCK : Describe what's on the command line                   ;AN000;
;-------------------------------------------------------------------------------;AN000;
PARMSX	LABEL BYTE								;AN000;
	DB	0,2			; Max. 2 positional parameters		;AN000;
	DW	TYPE_CTL		; Offset of type control block		;AN000;
	DW	PROF_CTL		; Offset of profile control block	;AN000;
										;AN000;
	DB	4			; Max. 4 switch types			;AN000;
	DW	PRINTBOX_CTL		; Offset of control for Printbox	;AN000;
	DW	R_CTL			; Offset of control for /R		;AN000;
	DW	B_CTL			; Offset of control for /B		;AN000;
	DW	LCD_CTL 		; Offset of control for /LCD		;AN000;
										;AN000;
	DB	0			; No keywords				;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
;										;AN000;
; Describe the printer type parameter:						;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
TYPE_CTL LABEL	WORD								;AN000;
	DW	2001H		 ; Optional simple string			;AN000;
	DW	0002H		 ; Capitalize it				;AN000;
	DW	TYPE_RESULT	 ; Offset of result buffer for printer type	;AN000;
	DW	NO_VALUES	 ; No values (NOTE: The type returned is checked;AN000;
	DB	0		 ;		   for validity by LOAD_PROFILE);AN000;
										;AN000;
NO_VALUES	DB	0							;AN000;
										;AN000;
TYPE_RESULT	LABEL BYTE							;AN000;
	DB	?		; Type						;AN000;
	DB	?		; Item tag					;AN000;
	DW	?		; Offset of synomym				;AN000;
	DD	?		; Pointer to string found			;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
;										;AN000;
; Describe the format of the PROFILE parameter: 				;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
										;AN000;
PROF_CTL LABEL WORD								;AN000;
	DW	0201H		; File spec. - Optional 			;AN000;
	DW	0001h		; Capitalize					;AN000;
	DW	PROFILE_RESULT	; Offset of result buffer for Profile		;AN000;
	DW	NO_VALUES	; No values needed				;AN000;
	DB	0								;AN000;
										;AN000;
										;AN000;
PROFILE_RESULT	LABEL BYTE							;AN000;
	DB	?		; Type						;AN000;
	DB	?		; Item tag					;AN000;
	DW	?		; Offset of synomym				;AN000;
	DD	?		; Offset of string				;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
;										;AN000;
; Describe the format of /R							;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
R_CTL	LABEL WORD								;AN000;
	DW	0		;						;AN000;
	DW	0		;						;AN000;
	DW	R_RESULT	; Offset of result buffer for a simple switch	;AN000;
	DW	NO_VALUES	; No values can be given with these switches.	;AN000;
	DB	1		; 1 name for this switch			;AN000;
	DB	"/R",0          ;   Reverse                                     ;AN000;
										;AN000;
R_RESULT LABEL BYTE								;AN000;
	DB	?		; Type						;AN000;
	DB	?		; Item tag					;AN000;
	DW	?		; Offset of synomym				;AN000;
	DD	?		; Offset of value				;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
;										;AN000;
; Describe the format of /B							;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
B_CTL	LABEL WORD								;AN000;
	DW	0		;						;AN000;
	DW	0		;						;AN000;
	DW	B_RESULT	; Offset of result buffer for a simple switch	;AN000;
	DW	NO_VALUES	; No values can be given with these switches.	;AN000;
	DB	1		; 1 name allowed for this switch		;AN000;
	DB	"/B",0          ;   Background                                  ;AN000;
										;AN000;
B_RESULT LABEL BYTE								;AN000;
	DB	?		; Type						;AN000;
	DB	?		; Item tag					;AN000;
	DW	?		; Offset of synomym				;AN000;
	DD	?		; Offset of value				;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
;										;AN000;
; Describe the format of /LCD							;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
LCD_CTL LABEL WORD								;AN000;
	DW	0		;						;AN000;
	DW	0		;						;AN000;
	DW	LCD_RESULT	; Offset of result buffer for a /LCD		;AN000;
	DW	NO_VALUES	; No values can be given with these switches.	;AN000;
	DB	1		; 1 name:					;AN000;
	DB	"/LCD",0        ;  /LCD                                         ;AN000;
										;AN000;
LCD_RESULT  LABEL BYTE								;AN000;
	DB	?		; Type						;AN000;
	DB	?		; Item tag					;AN000;
	DW	?		; Offset of synomym				;AN000;
	DD	?		; Offset of value				;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
;										;AN000;
; Describe the format of the PRINTBOX switch:					;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
PRINTBOX_CTL LABEL WORD 							;AN000;
	DW	2001H		; Optional simple string			;AN000;
	DW	0001H		; Capitalize					;AN000;
	DW	PRINTBOX_RESULT ; Offset of result buffer for Printbox		;AN000;
	DW	NO_VALUES	; Values will be validated when loading profile ;AN000;
	DB	2		; 2 synomym for this switch:			;AN000;
	DB	"/PRINTBOX",0   ;                                               ;AN000;
	DB	"/PB",0                                                         ;AN000;
										;AN000;
PRINTBOX_RESULT LABEL BYTE							;AN000;
	DB	?		; Type						;AN000;
	DB	?		; Item tag					;AN000;
	DW	?		; Offset of synomym				;AN000;
	DD	?		; Offset of value				;AN000;
										;AN000;
;===============================================================================;AN000;
;										;AN000;
; DOS "MESSAGE RETRIEVER" Substitution list control block:                      ;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
SUBLIST        LABEL DWORD		   ; List for substitution:		;AN000;
	       DB	11		   ; Size of this list			;AN000;
	       DB	0		   ; Reserved				;AN000;
SAVE_SI        DD	?		   ; Ptr to data item			;AN001;
	       DB	1		   ; Variable to be substitued: %1	;AN000;
	       DB	00010000B	   ; %1 is an ASCIIZ string left justifi;AN000;ed
	       DB	0		   ; Unlimited size for %1		;AN000;
	       DB	1		   ; Minimum size is 1 character	;AN000;
	       DB	" "                ; Delimiter is "space"               ;AN000;
										;AN000;
;===============================================================================;AN000;
;										;AN000;
; START OF EXECUTABLE CODE:							;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
										;AN000;
PARSE_PARMS_START:								;AN000;
	PUSH	AX								;AN000;
	PUSH	BX								;AN000;
	PUSH	CX								;AN000;
	PUSH	DX								;AN000;
	PUSH	SI								;AN000;
	PUSH	DI								;AN000;
	PUSH	ES								;AN000;
;-------------------------------------------------------------------------------;AN000;
; Set up addressibility for the parser						;AN000;
;-------------------------------------------------------------------------------;AN000;
	MOV	SI,81H			; DS:SI := Command line parameters	;AN000;
					;  to be parsed 			;AN000;
	PUSH	CS								;AN000;
	POP	ES								;AN000;
	LEA	DI,PARMS		; ES:DI := Parms control block		;AN000;
;(deleted ;AN001;) XOR DX,DX		; CX,DX must be zero for the		;AN000;
	XOR	CX,CX			; Initially, CX should be zero		;AN001;
	MOV	AX,0			; No error yet				;AN000;
;-------------------------------------------------------------------------------;AN000;
; Parse FIRST argument								;AN000;
;-------------------------------------------------------------------------------;AN000;
;(deleted ;AN001;) CALL SYSPARSE	; Get one argument from the command line;AN000;
	CALL	CALL_SYSPARSE		; Get one argument from the command line;AN001;
;(deleted ;AN001;) MOV BX,DX		; BX := Offset of result block		;AN000;
.WHILE <AX EQ RC_NO_ERROR>		; While there is no error		;AN000;
;-------------------------------------------------------------------------------;AN000;
; Get the argument:								;AN000;
;-------------------------------------------------------------------------------;AN000;
       .SELECT									;AN000;
       .WHEN <BX EQ <OFFSET TYPE_RESULT>>					;AN000;
	  CALL	GET_TYPE							;AN000;
       .WHEN <BX EQ <OFFSET PROFILE_RESULT>>					;AN000;
	  CALL	GET_PROFILE_NAME						;AN000;
       .WHEN <BX EQ <OFFSET LCD_RESULT >>					;AN000;
	  CALL	GET_LCD 							;AN000;
       .WHEN <BX EQ <OFFSET R_RESULT>>						;AN000;
	  CALL	GET_REVERSE							;AN000;
       .WHEN <BX EQ <OFFSET B_RESULT>>						;AN000;
	  CALL	GET_BACKGROUND							;AN000;
       .WHEN <BX EQ <OFFSET PRINTBOX_RESULT>>					;AN000;
	  CALL	GET_PRINTBOX_ID 						;AN000;
       .OTHERWISE								;AN000;
;-------No result block was returned by the parser				;AN000;
	STC				; Set error				;AN000;
       .ENDSELECT								;AN000;
       .LEAVE C 			; IF error occurred while parsing the	;AN000;
					;  previous argument, exit the loop:	;AN000;
					;   stop parsing the command line.	;AN000;
;-------------------------------------------------------------------------------;AN000;
; Parse next argument:								;AN000;
;-------------------------------------------------------------------------------;AN000;
;(deleted ;AN001;) XOR DX,DX		;					;AN000;
;(deleted ;AN001;) CALL SYSPARSE	; Get one argument from the command line;AN000;
	CALL	CALL_SYSPARSE		; Get one argument from the command line;AN001;
;(deleted ;AN001;) MOV BX,DX		; ES:BX := Offset of result block	;AN000;
.ENDWHILE									;AN000;
;-------------------------------------------------------------------------------;AN000;
; Check for error, select and display an error message				;AN000;
;-------------------------------------------------------------------------------;AN000;
.IF <AL NE RC_EOL>			; IF an error occurred			;AN000;
.THEN					; then, display error message		;AN000;
    MOV 	CX,0			; Assume no substitutions		;AN000;
   .SELECT				; (CX := Number of substitutions	;AN000;
   .WHEN <AL EQ RC_TOO_MANY>		; When RC = Too many parameters 	;AN000;
	MOV	AX,TOO_MANY_PARMS	;   (AL = Message number to display)	;AN000;
   .WHEN <AL EQ RC_Not_In_Val>		; When RC = Not in value list provided	;AN000;
	MOV	AX,VALUE_NOT_ALLOWED	;   (AL = Message number to display)	;AN000;
   .WHEN <AL EQ RC_Not_In_Sw>		; When RC = Not in switch list provided ;AN000;
	MOV	CX,1			;   1 substitution in this message	;AN000;
	MOV	BYTE PTR [SI],0 	; PUT NUL AT END OF THIS PARM		;AN001;
	LEA	SI,SUBLIST		;   DS:[SI]:="Invalid parm" Substitution;AN000; list
;(deleted ;AN001;) LES DX,ES:[BX+4]	;   ES:DX := Offset of offending parm.	;AN000;
;(deleted ;AN001;) MOV [SI]+2,DX	;   Store offset to this offender in the;AN000;
	MOV	[SI]+4,ES		;    substitution list control block	;AN000;
	MOV	AX,INVALID_PARM 	;   AL := 'Invalid parameter' msg number;AN000;
   .WHEN <AL EQ RC_INVLD_COMBINATION>	; When RC = Invalid combination of parms;AN000;
	MOV	AX,INVALID_COMBINATION	;   (AL = Message number to display)	;AN000;
   .WHEN <AL EQ RC_DUPLICATE_PARMS>	; When RC = Invalid combination of parms;AN000;
	MOV	AX,DUPLICATE_PARM	;   (AL = Message number to display)	;AN000;
   .OTHERWISE				;					;AN000;
	MOV	AX,FORMAT_NOT_CORRECT	; RC = Anything else, tell the user	;AN000;
					;	something is wrong with his	;AN000;
   .ENDSELECT				;	 command line.			;AN000;
    CALL DISP_ERROR			; Display the selected error message	;AN000;
    STC 				; Indicate parse error occurred 	;AN000;
.ENDIF										;AN000;
										;AN000;
	POP	ES								;AN000;
	POP	DI								;AN000;
	POP	SI								;AN000;
	POP	DX								;AN000;
	POP	CX								;AN000;
	POP	BX								;AN000;
	POP	AX								;AN000;
	RET				; Return to GRAPHICS_INSTALL		;AN000;
										;AN000;
PARSE_PARMS ENDP								;AN000;
CALL_SYSPARSE PROC NEAR 		;COMMON INVOCATION OF SYSPARSE		;AN001;
;INPUT: - CX=ORDINAL VALUE							;AN001;
;	  DS:SI=WHERE COMMAND LINE IS, SAVED IN "SAVE_SI"                       ;AN001;
;	  ES:DI=WHERE PARMS DESCRIPTOR BLOCK IS 				;AN001;
;OUTPUT:  CX=NEW ORDINAL VALUE							;AN001;
;	  BX=OFFSET OF RESULT BLOCK, IF ONE IS RETURNED 			;AN001;
;	  SI=OFFSET OF CHAR BEYOND PARSED PARM IN COMMAND LINE			;AN001;
										;AN001;
	XOR	DX,DX			;CLEAR DX FOR PARSER			;AN001;
	MOV	WORD PTR SAVE_SI,SI	;REMEMBER WHERE TO START LOOKING	;AN001;
	CALL	SYSPARSE		;GO PARSE THE NEXT PARM 		;AN001;
										;AN001;
	MOV	BX,DX			; BX := Offset of result block		;AN001;
	RET				;RETURN TO CALLER			;AN001;
CALL_SYSPARSE ENDP								;AN001;
PAGE										;AN000;
;===============================================================================;AN000;
;										;AN000;
; PROCEDURE_NAME: GET_PROFILE							;AN000;
;										;AN000;
; INPUT:  ES:[BX] := Result block						;AN000;
;										;AN000;
; OUTPUT: PROFILE_PATH = The profile file name and path (ASCIIZ string) 	;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
GET_PROFILE_NAME PROC								;AN000;
	PUSH	AX								;AN000;
	PUSH	BX								;AN000;
	PUSH	DX								;AN000;
	PUSH	SI								;AN000;
	PUSH	DI								;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; Get the name of the profile path found on the command line:			;AN000;
;-------------------------------------------------------------------------------;AN000;
	MOV	DI,ES:[BX+4]	; DI := Offset of filename found		;AN000;
	XOR	BX,BX		; BX := Byte index				;AN000;
	MOV	SI,OFFSET PROFILE_PATH	; [BX][SI] := Where to store it 	;AN000;
										;AN000;
.IF <<BYTE PTR [DI]> NE 0>	; Don't copy a NULL parm                        ;AN000;
  .REPEAT			; While not end of path name (NULL terminated)	;AN000;
	MOV	AL,[BX][DI]	; Copy the byte (including the NULL)		;AN000;
	MOV	[BX][SI],AL							;AN000;
	INC	BX		; Get next one					;AN000;
  .UNTIL <<BYTE PTR [BX-1][DI]> EQ 0> ; 					;AN000;
.ENDIF										;AN000;
										;AN000;
	POP	DI								;AN000;
	POP	SI								;AN000;
	POP	DX								;AN000;
	POP	BX								;AN000;
	POP	AX								;AN000;
	CLC									;AN000;
	RET									;AN000;
GET_PROFILE_NAME ENDP								;AN000;
										;AN000;
PAGE										;AN000;
;===============================================================================;AN000;
;										;AN000;
; PROCEDURE_NAME: GET_TYPE							;AN000;
;										;AN000;
; INPUT:  ES:[BX] := Result block						;AN000;
;	  PRINTER_TYPE_LENGTH := Maximum length for the printer type string	;AN000;
;										;AN000;
; OUTPUT: PRINTER_TYPE_PARM = ASCIIZ string containing				;AN000;
;			       the Printer type.				;AN000;
;	  AX		    = Error code					;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
GET_TYPE PROC									;AN000;
	PUSH	BX								;AN000;
	PUSH	CX								;AN000;
	PUSH	SI								;AN000;
	PUSH	DI								;AN000;
										;AN000;
;---------------------------------------------------------------------- 	;AN000;
; Overwrite the DEFAULT TYPE with the type found on the command line		;AN000;
;---------------------------------------------------------------------- 	;AN000;
  MOV	  SI,ES:[BX+4]		       ; DS:SI := Offset of printer type found	;AN000;
 .IF <<BYTE PTR [SI]> NE 0>	       ; Do not copy an empty string		;AN000;
 .THEN				       ;					;AN000;
    MOV     CL,PRINTER_TYPE_LENGTH     ; CX := Maximum number of bytes		;AN000;
    XOR     CH,CH		       ;	to copy 			;AN000;
    MOV     DI,OFFSET PRINTER_TYPE_PARM; ES:DI := Where to store it		;AN000;
    REP     MOVSB		       ; Copy the string			;AN000;
  ;----------------------------------------------------------------------	;AN000;
  ; Verify that the string supplied is not too long:				;AN000;
  ;----------------------------------------------------------------------	;AN000;
   .IF	<<BYTE PTR [DI-1]> EQ 0>       ; If the last byte is a null		;AN000;
   .THEN			       ; then, the string was not longer	;AN000;
				       ;       than the maximum 		;AN000;
      CLC			       ;   Clear the carry flag = No error	;AN000;
   .ELSE			       ; else, string provided is too long	;AN000;
      MOV  AX,RC_Not_In_Sw	       ;   Error := RC for Invalid parm 	;AN000;
      STC			       ; Set error				;AN000;
   .ENDIF			       ; ENDIF string too long			;AN000;
 .ENDIF 			       ; ENDIF string provided			;AN000;
										;AN000;
GET_TYPE_END:									;AN000;
	POP	DI								;AN000;
	POP	SI								;AN000;
	POP	CX								;AN000;
	POP	BX								;AN000;
	RET									;AN000;
GET_TYPE  ENDP									;AN000;
										;AN000;
PAGE										;AN000;
;===============================================================================;AN000;
;										;AN000;
; PROCEDURE_NAME: GET_REVERSE							;AN000;
;										;AN000;
; INPUT:  ES:[BX]	:= Result block 					;AN000;
;	  SWITCH_PARSED := The command line switches parsed so far (bit mask)	;AN000;
;										;AN000;
; OUTPUT: CS:[BP].SWITCHES (Bit mask in the Shared data area) is updated	;AN000;
;			    with the value of the switch found. 		;AN000;
;	  GOT_R is set in SWITCH_PARSED 					;AN000;
;	  AX		:= Error message number.				;AN000;
;	  CARRY FLAG IS SET IF ERROR FOUND					;AN000;
;										;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
GET_REVERSE	PROC								;AN000;
										;AN000;
	TEST	SWITCH_PARSED,GOT_R		; If already parsed this switch ;AN000;
	JNZ	DUPLICATE_R			; then, error			;AN000;
	OR	SWITCH_PARSED,GOT_R		; else, say we parsed it.	;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; Set the Reverse switch in the Shared data area				;AN000;
;-------------------------------------------------------------------------------;AN000;
	OR	CS:[BP].SWITCHES,REVERSE_SW	; Set the command line switch	;AN000;
	CLC					; Clear the error flag		;AN000;
	JMP	SHORT GET_REVERSE_END		; Return			;AN000;
										;AN000;
DUPLICATE_R:					; Already got this switch	;AN000;
	MOV	AX,RC_DUPLICATE_PARMS		; AX := error message number	;AN000;
	STC					; SET ERROR			;AN000;
GET_REVERSE_END:								;AN000;
										;AN000;
	RET									;AN000;
GET_REVERSE	ENDP								;AN000;
										;AN000;
PAGE										;AN000;
;===============================================================================;AN000;
;										;AN000;
; PROCEDURE_NAME: GET_BACKGROUND						;AN000;
;										;AN000;
; INPUT:  ES:[BX] := Result block						;AN000;
;	  SWITCH_PARSED := The command line switches parsed so far (bit mask)	;AN000;
;										;AN000;
; OUTPUT: CS:[BP].SWITCHES (Bit mask in the Shared data area) is updated	;AN000;
;			    with the value of the switch found. 		;AN000;
;										;AN000;
;	  GOT_B is set in SWITCH_PARSED 					;AN000;
;	  AX		:= Error message number.				;AN000;
;	  CARRY FLAG IS SET IF ERROR FOUND					;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
GET_BACKGROUND	PROC								;AN000;
										;AN000;
	TEST	SWITCH_PARSED,GOT_B		; If already parsed this switch ;AN000;
	JNZ	DUPLICATE_B			; then, error			;AN000;
	OR	SWITCH_PARSED,GOT_B		; else, say we parsed it.	;AN000;
;-------------------------------------------------------------------------------;AN000;
; Set the switch in the Shared data area					;AN000;
;-------------------------------------------------------------------------------;AN000;
	OR	CS:[BP].SWITCHES,BACKGROUND_SW	; Set the command line switch	;AN000;
	CLC					; Clear the error flag		;AN000;
	JMP	SHORT GET_BACKGROUND_END	; Return			;AN000;
										;AN000;
DUPLICATE_B:					; Already got this switch	;AN000;
	MOV	AX,RC_DUPLICATE_PARMS		; AX := error message number	;AN000;
	STC					; SET ERROR			;AN000;
										;AN000;
GET_BACKGROUND_END:								;AN000;
	RET									;AN000;
GET_BACKGROUND	ENDP								;AN000;
										;AN000;
PAGE										;AN000;
;===============================================================================;AN000;
;										;AN000;
; PROCEDURE_NAME: GET_LCD							;AN000;
;										;AN000;
; INPUT:  SWITCH_PARSED   := The command line switches parsed so far (bit mask) ;AN000;
;										;AN000;
; OUTPUT: PRINTBOX_ID_PTR := Point to /LCD ASCIIZ string.			;AN000;
;	  GOT_B is set in SWITCH_PARSED 					;AN000;
;	  AX		  := Error message number.				;AN000;
;	  CARRY FLAG IS SET IF ERROR FOUND					;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
; Data Referenced:								;AN000;
;										;AN000;
;	  LCD_BOX = An ASCIIZ string representing the LCD printbox id.		;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
GET_LCD PROC									;AN000;
										;AN000;
	TEST	SWITCH_PARSED,GOT_LCD	   ; If already parsed this switch	;AN000;
	JNZ	DUPLICATE_LCD		   ; then, error: Duplicate switch	;AN000;
	TEST	SWITCH_PARSED,GOT_PRINTBOX ; If printbox already mentioned	;AN000;
	JNZ	BAD_COMBINATION 	   ; then, error: Invalid combination	;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; Set the pointer to the print box id to "LCD"                                  ;AN000;
;-------------------------------------------------------------------------------;AN000;
	MOV	AX,OFFSET LCD_BOX	   ; PRINTBOX id := LCD 		;AN000;
	MOV	PRINTBOX_ID_PTR,AX	   ; Save pointer to this printbox id.	;AN000;
	OR	SWITCH_PARSED,GOT_LCD	   ; Say we found this switch		;AN000;
	CLC				   ; Clear the error flag		;AN000;
	JMP	SHORT GET_LCD_END	   ; Return				;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; /LCD was already parsed:							;AN000;
;-------------------------------------------------------------------------------;AN000;
DUPLICATE_LCD:				   ; Already got this switch		;AN000;
	MOV	AX,RC_DUPLICATE_PARMS	   ; AX := error message number 	;AN000;
	STC				   ; SET ERROR				;AN000;
	JMP	SHORT GET_LCD_END	   ; Return				;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; /PRINTBOX was already parsed: 						;AN000;
;-------------------------------------------------------------------------------;AN000;
BAD_COMBINATION:			   ; /LCD and /PRINTBOX invalid at same ;AN000;
	MOV	AX,RC_INVLD_COMBINATION    ;  time, Set the error flag		;AN000;
	STC				   ;   AX := Error code 		;AN000;
										;AN000;
GET_LCD_END:									;AN000;
	RET									;AN000;
GET_LCD 	ENDP								;AN000;
										;AN000;
PAGE										;AN000;
;===============================================================================;AN000;
;										;AN000;
; PROCEDURE_NAME: GET_PRINTBOX							;AN000;
;										;AN000;
; INPUT:  ES:[BX]	:= Result block 					;AN000;
;	  SWITCH_PARSED := The command line switches parsed so far (bit mask)	;AN000;
;										;AN000;
; OUTPUT: DEFAULT_BOX	:= Is overwritten to contain the printbox id. found on	;AN000;
;			    the command line.					;AN000;
;	  GOT_PRINTBOX is set in SWITCH_PARSED					;AN000;
;	  AX		:= Error message number.				;AN000;
;	  CARRY FLAG IS SET IF ERROR FOUND					;AN000;
;										;AN000;
;-------------------------------------------------------------------------------;AN000;
GET_PRINTBOX_ID PROC								;AN000;
										;AN000;
	PUSH	CX								;AN000;
	PUSH	SI								;AN000;
	PUSH	DI								;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; Test for error in the printbox statement:					;AN000;
;-------------------------------------------------------------------------------;AN000;
	TEST	SWITCH_PARSED,GOT_LCD	    ; If /LCD	  already mentioned	;AN000;
	JNZ	BAD_COMBINATION2	    ; then, error: Invalid combination	;AN000;
	TEST	SWITCH_PARSED,GOT_PRINTBOX  ; If already parsed this switch	;AN000;
	JNZ	DUPLICATE_PRINTBOX	    ; then, error: Duplicate switch	;AN000;
										;AN000;
	MOV	DI,ES:[BX+4]		    ; DI := Offset of switch VALUE found;AN000;
										;AN000;
       .IF <<BYTE PTR [DI]> EQ 0>	    ; IF no printbox id 		;AN000;
       .THEN				    ; then,				;AN000;
	 ;----------------------------------------------------------------------;AN000;
	 ; No printbox id. was found:						;AN000;
	 ;----------------------------------------------------------------------;AN000;
	  MOV	  AX,FORMAT_NOT_CORRECT     ;	AX := Error code		;AN000;
	  STC				    ;	Set the error flag		;AN000;
       .ELSE				    ; else,				;AN000;
	  OR	  SWITCH_PARSED,GOT_PRINTBOX;	Say we found this switch	;AN000;
	 ;----------------------------------------------------------------------;AN000;
	 ; Overwrite DEFAULT_BOX with the Printbox id. found			;AN000;
	 ;----------------------------------------------------------------------;AN000;
	  MOV	  CL,PRINTBOX_ID_LENGTH     ;	  CX := Maximum number of bytes ;AN000;
	  XOR	  CH,CH 		    ;		 to copy		;AN000;
	  MOV	  SI,DI 		    ;	  [DS][SI] :=  Value found	;AN000;
	  MOV	  DI,OFFSET DEFAULT_BOX     ;	  [ES][DI] :=  Default value	;AN000;
	  REP	  MOVSB 		    ;	  Copy the string		;AN000;
	 ;----------------------------------------------------------------------;AN000;
	 ; Verify that the Printbox id. string is not too long: 		;AN000;
	 ;----------------------------------------------------------------------;AN000;
	 .IF  <<BYTE PTR [DI-1]> EQ 0>	    ; If the last byte is a null	;AN000;
	 .THEN				    ; then, the string was not longer	;AN000;
					    ;	    than the maximum		;AN000;
	    CLC 			    ;	Clear the carry flag = No error ;AN000;
	 .ELSE				    ; else, string provided is too long ;AN000;
	    MOV  AX,RC_Not_In_Sw	    ;	Error := RC for Invalid parm	;AN000;
	    STC 			    ; Set error 			;AN000;
	 .ENDIF 			    ; ENDIF printbox id. too long	;AN000;
       .ENDIF				    ; ENDIF printbox id. provided	;AN000;
										;AN000;
	JMP	SHORT GET_PRINTBOX_END	    ; Return				;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; /PRINTBOX was already parsed: 						;AN000;
;-------------------------------------------------------------------------------;AN000;
DUPLICATE_PRINTBOX:			    ; Already got this switch		;AN000;
	MOV	AX,RC_DUPLICATE_PARMS	    ; AX := error message number	;AN000;
	STC				    ; SET ERROR 			;AN000;
	JMP	SHORT GET_PRINTBOX_END	    ; Return				;AN000;
										;AN000;
;-------------------------------------------------------------------------------;AN000;
; /LCD was already parsed:							;AN000;
;-------------------------------------------------------------------------------;AN000;
BAD_COMBINATION2:			    ; /LCD and /PRINTBOX invalid at same;AN000;
	MOV	AX,RC_INVLD_COMBINATION     ;  time, Set the error flag 	;AN000;
	STC				    ;	AX := Error code		;AN000;
										;AN000;
GET_PRINTBOX_END:								;AN000;
	POP	DI								;AN000;
	POP	SI								;AN000;
	POP	CX								;AN000;
	RET									;AN000;
GET_PRINTBOX_ID ENDP								;AN000;
										;AN000;
CODE  ENDS									;AN000;
	END									;AN000;
