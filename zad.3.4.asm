;Zadanie 3.4. Napisać program w asemblerze, który wczyta liczbę dziesiętną z klawiatury i
;wyświetli na ekranie jej reprezentację w systemie szesnastkowym. W programie wykorzystać
;podprogramy wczytaj_do_EAX i wyswietl_EAX_hex.
;first, not working yey, version
.686
.model flat
extern __write : PROC
extern __read : PROC 
extern _ExitProcess@4 : PROC
public _main
.data
znaki	db 12 dup (?)
obszar db 12 dup (?)
dziesiec dd 10 ; mnożnik
.code
wyswietl_EAX PROC
			 pusha
		mov esi, 10 ; indeks w tablicy 'znaki'
		mov ebx, 10	;dzielnik równy 10
	konwersja:
		mov edx, 0	;zerowanie starszej części dzielnej
		div ebx		;dzielenie przez 10, reszta w edx, iloraz w eax
		add	dl, 30H ;zamiana reszty z dzielenia na kod ASCII
		mov znaki  [esi], dl ;zapisanie cyfry w kodzie ASCII
		dec esi ;zmniejszenie indeksu
		cmp eax, 0	;sprawdzenie czy iloraz = 0
		jne konwersja ;skok, gdy iloraz niezerowy
	
		;wypełnienie pozostałych bajtów spacjami i wpsianie znaków nowego wiersza
	wypeln:
		or esi,esi 
		jz wyswietl  ;skok gdy esi=0
		mov byte PTR znaki [esi],20H ;kod spacji
		dec esi ;zmiejszenie indeksu
		jmp wypeln
	wyswietl:
		mov byte PTR znaki [11], 0AH ;kod nowego wiersza
	;wyswietlenie cyfr na ekranie
		push dword PTR 12 ;liczba wyswietlanych znaków
		push dword PTR OFFSET znaki ;adres wyśw. obszaru
		push dword PTR 1 ;numer urządzenia (ekran)
		call __write ;wiświetlenie liczby na ekranie
		add esp, 12 ;usunięcie parametrów ze stosu
		
				popa
				ret
wyswietl_EAX    ENDP

wczytaj_do_EAX	PROC
	push ebx
	push ecx
	;max ilość znaków wczytywanej liczby
	push dword PTR 12
	push dword PTR OFFSET obszar ;adres obszaru pamięci
	push dword PTR 0 ;numer klawiatury
	call __read    ;odczytywanie znaków z klawiatury

	add esp, 12 ;usunięcie parametrów ze stosu

	;bieżąca wartość przekształcanej liczby przechowywana jest w rejestrze EAX
	;przyjmujemy 0 jako wartość początkową
	mov		eax, 0
	mov ebx, OFFSET obszar ;adres obszaru ze znakami

pobieraj_znaki:
	mov	cl, [ebx] ;pobranie kolejnej cyfry w kodzie ASCII
	inc ebx
	cmp cl, 10 ;sprawdzenie czy naciśnięto Enter
	je	byl_enter ;skok jeśli naciśnięto Enter
	sub cl,30H ;zamiana kodu ASCII na wartość cyfry
	movzx	ecx, cl ;przechowywanie wartości cyfry w rejestrze ECX

	;mnożenie wcześniej obliczonej wartości razy 10
	mul dword PTR dziesiec
	add eax, ecx  ;dodatnie ostatnio odczytanej cyfry
	jmp pobieraj_znaki  ;skok na poczatek petli

byl_enter:  
	pop ecx
	pop ebx
;wartość binarna wprowadzonej liczby znajduje się teraz w rejestrze EAX
		ret
wczytaj_do_EAX	ENDP
_main PROC
ptl:
	call wczytaj_do_EAX
	cmp eax, 6000
	jae ptl ;jesli 6000 <= to trzeba wpisac nowa liczbe
	mul eax
	call wyswietl_EAX
	cmp EAX, 0
	jne ptl
	push 0
	call _ExitProcess@4
_main ENDP
END
