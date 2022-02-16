/*	
    Archivo:		prelab4main.S
    Dispositivo:	PIC16F887
    Autor:		Jorge Cerón 20288
    Compilador:		pic-as (v2.30), MPLABX V6.00

    Programa:		Contador binario de 4 bits incremento/decremento con interrupciones
    Hardware:		LEDs en puerto A

    Creado:			15/02/22
    Última modificación:	15/02/22	
*/
PROCESSOR 16F887
#include <xc.inc>

; configuracion 1
  CONFIG  FOSC = INTRC_NOCLKOUT // Oscillador Interno sin salidas
  CONFIG  WDTE = OFF            // WDT (Watchdog Timer Enable bit) disabled (reinicio repetitivo del pic)
  CONFIG  PWRTE = ON            // PWRT enabled (Power-up Timer Enable bit) (espera de 72 ms al iniciar)
  CONFIG  MCLRE = OFF           // El pin de MCL se utiliza como I/O
  CONFIG  CP = OFF              // Sin proteccion de codigo
  CONFIG  CPD = OFF             // Sin proteccion de datos
  
  CONFIG  BOREN = OFF           // Sin reinicio cunado el voltaje de alimentación baja de 4V
  CONFIG  IESO = OFF            // Reinicio sin cambio de reloj de interno a externo
  CONFIG  FCMEN = OFF           // Cambio de reloj externo a interno en caso de fallo
  CONFIG  LVP = ON              // programación en bajo voltaje permitida

; configuracion  2
  CONFIG  WRT = OFF             // Protección de autoescritura por el programa desactivada
  CONFIG  BOR4V = BOR40V        // Reinicio abajo de 4V, (BOR21V = 2.1V)

UP	EQU 0			// UP equivalente a 0
DOWN	EQU 1			// DOWN equivalente a 1

; Status para interrupciones
PSECT udata_shr			// Variables globales en memoria compartida
    WTEMP:	    DS 1	// 1 byte
    STATUSTEMP:	    DS 1	// 1 byte
     
PSECT resVect, class=CODE, abs, delta=2
;----------------vector reset----------------
ORG 00h				// Posición 0000h para el reset
resVect:
    PAGESEL	main		//Cambio de página
    GOTO	main

;----------------vector interrupcion---------------
ORG 04h				// Posición 0004h para las interrupciones
PUSH:				// PC a pila
    MOVWF   WTEMP		// Se mueve W a la variable WTEMP
    SWAPF   STATUS, W		// Swap de nibbles del status y se almacena en W
    MOVWF   STATUSTEMP		// Se mueve W a la variable STATUSTEMP
ISR:				// Rutina de interrupción
    BTFSC   RBIF		// Analiza la bandera de cambio del PORTB si esta encendida (si no lo está salta una linea)
    CALL    INTERRUPIOCB	// Se llama la rutina de interrupción del puerto B
    BANKSEL PORTA
POP:				// Intruccion movida de la pila al PC
    SWAPF   STATUSTEMP, W	// Swap de nibbles de la variable STATUSTEMP y se almacena en W
    MOVWF   STATUS		// Se mueve W a status
    SWAPF   WTEMP, F		// Swap de nibbles de la variable WTEMP y se almacena en WTEMP 
    SWAPF   WTEMP, W		// Swap de nibbles de la variable WTEMP y se almacena en w
    RETFIE

INTERRUPIOCB:
    BANKSEL PORTA
    BTFSS   PORTB, UP		// Analiza RB0 si no esta presionado (si está presionado salta una linea)
    INCF    PORTA		// Incremento en 1
    BTFSS   PORTB, DOWN		// Analiza RB1 si no esta presionado (si está presionado salta una linea)
    DECF    PORTA		// Disminución en 1
    BCF	    RBIF		// Se limpia la bandera de cambio de estado del PORTB
    
    RETURN

PSECT code, abs, delta=2   
;----------------configuracion----------------
ORG 100h
main:
    CALL    CONFIGIO	    // Se llama la rutina configuración de entradas y salidas
    CALL    CONFIGRELOJ	    // Se llama la rutina configuración del reloj
    CALL    CONFIGINTERRUP  // Se llama la rutina configuración de interrupciones
    CALL    CONFIIOCB	    // Se llama la rutina configuración de interrupcion en PORTB
    BANKSEL PORTA
    
loop:
    GOTO    loop	    // Regresa a revisar
    
CONFIGIO:
    BANKSEL ANSEL	    // Direccionar al banco 11
    CLRF    ANSEL	    // I/O digitales
    CLRF    ANSELH	    // I/O digitales
    
    BANKSEL TRISA	    // Direccionar al banco 01
    BSF	    TRISB, UP	    // RB0 como entrada
    BSF	    TRISB, DOWN	    // RB1 como entrada
    BCF	    TRISA, 0	    // RA0 como salida
    BCF	    TRISA, 1	    // RA1 como salida
    BCF	    TRISA, 2	    // RA2 como salida
    BCF	    TRISA, 3	    // RA3 como salida
    
    BCF	    OPTION_REG, 7   // RBPU habilita las resistencias pull-up 
    BSF	    WPUB, UP	    // Habilita el registro de pull-up en RB0 
    BSF	    WPUB, DOWN	    // Habilita el registro de pull-up en RB0
    
    BANKSEL PORTA	    // Direccionar al banco 00
    CLRF    PORTA	    // Se limpia PORTA
    CLRF    PORTB	    // Se limpia PORTB

    RETURN
    
CONFIGRELOJ:
    BANKSEL OSCCON	    // Direccionamiento al banco 01
    BSF	    OSCCON, 0	    // SCS en 1, se configura a reloj interno
    BSF	    OSCCON, 6	    // bit 6 en 1
    BCF	    OSCCON, 5	    // bit 5 en 0
    BSF	    OSCCON, 4	    // bit 4 en 1
    // Frecuencia interna del oscilador configurada a 2MHz
    RETURN  
    
CONFIGINTERRUP:
    BANKSEL INTCON
    BSF	    GIE		    // Habilita interrupciones globales
    BSF	    RBIE	    // Habilita interrupciones de cambio de estado del PORTB
    BCF	    RBIF	    // Se limpia la banderda de cambio del puerto B
    
    RETURN

CONFIIOCB:		    // Interrupt on-change PORTB register
    BANKSEL TRISA
    BSF	    IOCB, UP	    // Interrupción control de cambio en el valor de B
    BSF	    IOCB, DOWN	    // Interrupción control de cambio en el valor de B
    
    BANKSEL PORTA
    MOVF    PORTB, W	    // Termina la condición de mismatch, compara con W
    BCF	    RBIF	    // Se limpia la bandera de cambio de PORTB
    RETURN
END