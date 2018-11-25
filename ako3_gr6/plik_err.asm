comment | W 48-bajtowej tablicy  bufor  znajduje siê pewien tekst zakodowany w formacie UTF-8.
Napisaæ program w asemblerze, który wyœwietli ten tekst na ekranie 
w postaci komunikatu typu MessageBoxW. W poni¿szej tablicy wystêpuj¹ ci¹gi UTF-8 1-, 2-, 3- i 4-bajtowe.
Uwaga: prawid³owe znaki poci¹gu oraz autobusu wyswietlane s¹ systemach Windows 8 i Windows 10.
W kodzie jest 5 b³êdów
|

.686
.model flat

extern _MessageBoxW@16 : proc
extern _ExitProcess@4 : proc


public _main

.data
; bufor wejsciowy ze znakami w utf-8
bufor	db	50H, 6FH, 0C5H, 82H, 0C4H, 85H, 63H, 7AH, 65H, 6EH, 69H, 61H, 20H	
		db  0F0h, 9Fh, 9Ah, 82H
		db	20h, 20H,  6BH, 6FH, 6CH, 65H, 6AH, 6FH, 77H, 6FH, 20H
		db 	0E2H, 80H, 93h
		db	20H, 61H, 75H, 74H, 6FH, 62H, 75H, 73H, 6FH, 77H, 65H, 20H, 20H
		db	0F0h, 9FH, 9AH, 8CH, 0E2H, 91H, 0A4H	


rozmiar = $ - bufor

;bufor wynikowy ze znakami w utf-16
wynik  db 2*(rozmiar+1) dup (0)

;tytul okna do wyswietlenia
tytul  dw 'T','y','t','u',0142h,0
.code
_main PROC

	;mov esi,0		; indeks bajtu w tablicy bufor
	;mov edi,0		; indeks bajtu w tablicy wynik
	mov esi,OFFSET bufor   ; ustawienia esi na adres efektywny lancucha zrodlowego w utf-8
	mov edi,OFFSET wynik   ; ustawienie edi na adres efektywny lanucha docelowego w utf-16


	mov ecx,rozmiar		; liczba wykonan petli

konwersja:
	;stc		; ustawenie znacznika CF
			;pobierz bajt z bufora wejsciowego
	mov al,[esi]
	;dokonaj oceny poczatkowego prefiksu w pierwszym znaku w utf-8
	rcl al,1
	jnc jeden_bajt   ; jednobajtowy znak
	rcl al,2
	jnc dwa_bajty    ; dwubajtowy znak
	rol al,1
	jnc trzy_bajty   ; trzybajtowy znak
	jmp cztery_bajty

jeden_bajt:
	ror al,1		; przywrócenie wlasciwej kolejnosci
	clc
	movzx bx,al		; rozszerzenie na znak utf-16
	mov [edi],bx	; zapis do lanucha wynikowego
	lea  edi,[edi+2]	; ustawienie wskaznika zapisu na nastêpny znak
	inc esi		; zwiekszenie wskaznika odczytu o 2 bajty
	sub ecx,1		; zmniejszenie licznika znaków do analizy o 2 przeczytane
	jnz konwersja
	jmp wyswietlanie


dwa_bajty:
		mov bx,0		; miejsce na znak utf-16
		mov bl,[esi+1]	; najstarszy bajt znaku utf-8  110xxxxx   ;najpierw najmlodszy
		and bl, 00011111b	; maska  -> 000xxxxx
		shl bx,6
		mov al,[esi]	;  kolejna czeœæ znaku utf-8 do al -> 10xxxxxx
		and al, 111111b  ; maska  -> 00xxxxxx 
	    xor bl,al		; sklejenie bitów 
		mov [edi],bx	; zapis do lanucha wynikowego
		
		add edi,2	; ustawienie wskaznika zapisu na nastêpny znak
		add esi,2	; zwiekszenie wskaznika odczytu o 2 bajty
		sub ecx,2	; zmniejszenie licznika znaków do analizy o 2 przeczytane
		jnz konwersja
		jmp wyswietlanie	

trzy_bajty:
		mov bx,0		; miejsce na znak utf-16
		mov bl,[esi]	; najstarszy bajt znaku ut-8  1110xxxx
		and bl,1111b	; maska  -> 0000xxxx
		shl bx,8		; 
		mov bl,[esi+1]	;  bl -> 10xxxxxx
		shl bl,2		;  bl -> xxxxxx00
		shl bx,4		;  bx -> xxxxxxxx xx000000

		mov al,[esi+2]  ; ostatni bajt utf-8
		and al,111111b	; zerowanie 2 najstarszych bitów al -> 00xxxxxx
		or bl,al		; w bx koncowy wynik

		mov [edi],bx	; zapisanie znaku w buforze wynikowym
		
		add edi,2		; ustawienie wskaznika zapisu na nastêpny znak
		add esi,3		; zwiekszenie wskaznika odczytu o 3 bajty	
		sub ecx,3	    ; zmniejszenie licznika	
		jnz konwersja
		jmp wyswietlanie	
	
cztery_bajty:
		mov ebx,0		; miejsce na znak utf-16
		mov bl,[esi]	; najstarszy bajt znaku ut-8  11110xxx
		and bl,111b		; maska  -> 00000xxx
		shl bx,8		;	bx -> 00000xxx 00000000 
		mov bl,[esi+1]	;  bl -> 10xxxxxx
		shl bl,2		;  bl -> xxxxxx00
		shl bx,5		;  bx -> xxxxxxxx x0000000

		mov al,[esi+2]  ; ostatni bajt utf-8
		and al,111111b	; zerowanie 2 najstarszych bitów al -> 00xxxxxx
		shl al,1		; al-> 0xxxxxx0
		or bl,al		; w bx -> xxxxxxxx xxxxxxx0

		mov al,[esi+3]	; ostatni, czwarty bajt z utf-8
		and al,111111b  ; wyzerowanie dwóch najstarszych bitów
		shl ebx,5		; ebx -> 0000 0000 000x xxxx  xxxx xxxx  xx00 0000
		or bl,al	    ; ebx -> 0000 0000 000x xxxx  xxxx xxxx  xxxx xxxx
		; w ebx mamy 21 bitów kodu Unicode

		; w³aœciwe kodowanie na utf-16
		sub ebx,10000h
		mov eax,ebx			; utworzenie kopii rejestru
		shr eax,10			;  0000 0000 0000 0000 0000 00xx xxxx xxxx
		or  eax, 1101100000000000b  ; w ax - starszy znak utf-16

		shl ebx,21
		shr ebx,21

		mov edx,110111b		; prefiks drugiego znaku
		shl edx,10			
		or ebx,edx		 ; bx - drugi, m³odszy znak utf-16

		mov [edi],ax    ; zapis starszego znaku utf-16
		mov [edi+2],bx  ; zapis m³odszego znaku
		add edi,4		; ustawienie wskaznika zapisu na nastêpny znak
		add esi,4		; zwiekszenie wskaznika odczytu o 3 bajty	
		sub ecx,4	    ; zmniejszenie licznika	
		jnz konwersja
		jmp wyswietlanie	





wyswietlanie:	
	push 0			; identyfikator przycisków
	push OFFSET tytul  ; adres ³añcucha z tytu³em
	push OFFSET wynik   ; adres w³aœciwego napisu
	push 0			; uchwyt
	call _MessageBoxW@16

	push 0
	call _ExitProcess@4
_main ENDP
END
