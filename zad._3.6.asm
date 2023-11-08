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
dekoder db '0123456789ABCDEF'
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

wczytaj_do_EAX_hex PROC
; wczytywanie liczby szesnastkowej z klawiatury – liczba po
; konwersji na postać binarną zostaje wpisana do rejestru EAX
; po wprowadzeniu ostatniej cyfry należy nacisnąć klawisz
; Enter
push ebx
push ecx
push edx
push esi
push edi
push ebp
; rezerwacja 12 bajtów na stosie przeznaczonych na tymczasowe
; przechowanie cyfr szesnastkowych wyświetlanej liczby
sub esp, 12 ; rezerwacja poprzez zmniejszenie ESP
mov esi, esp ; adres zarezerwowanego obszaru pamięci
push dword PTR 10 ; max ilość znaków wczytyw. liczby
push esi ; adres obszaru pamięci
push dword PTR 0; numer urządzenia (0 dla klawiatury)
call __read ; odczytywanie znaków z klawiatury
; (dwa znaki podkreślenia przed read)
add esp, 12 ; usunięcie parametrów ze stosu
mov eax, 0 ; dotychczas uzyskany wynik
pocz_konw:
mov dl, [esi] ; pobranie kolejnego bajtu
inc esi ; inkrementacja indeksu
cmp dl, 10 ; sprawdzenie czy naciśnięto Enter
je gotowe ; skok do końca podprogramu
; sprawdzenie czy wprowadzony znak jest cyfrą 0, 1, 2 , ..., 9
cmp dl, '0'
jb pocz_konw ; inny znak jest ignorowany
cmp dl, '9'
ja sprawdzaj_dalej
sub dl, '0' ; zamiana kodu ASCII na wartość cyfry
dopisz:
shl eax, 4 ; przesunięcie logiczne w lewo o 4 bity
or al, dl ; dopisanie utworzonego kodu 4-bitowego
 ; na 4 ostatnie bity rejestru EAX
jmp pocz_konw ; skok na początek pętli konwersji
; sprawdzenie czy wprowadzony znak jest cyfrą A, B, ..., F
sprawdzaj_dalej:
cmp dl, 'A'
jb pocz_konw ; inny znak jest ignorowany
cmp dl, 'F'
ja sprawdzaj_dalej2
sub dl, 'A' - 10 ; wyznaczenie kodu binarnego
jmp dopisz
; sprawdzenie czy wprowadzony znak jest cyfrą a, b, ..., f
sprawdzaj_dalej2:
cmp dl, 'a'
jb pocz_konw ; inny znak jest ignorowany
cmp dl, 'f'
ja pocz_konw ; inny znak jest ignorowany
sub dl, 'a' - 10
jmp dopisz
gotowe:
; zwolnienie zarezerwowanego obszaru pamięci
add esp, 12
pop ebp
pop edi
pop esi
pop edx
pop ecx
pop ebx
ret
wczytaj_do_EAX_hex ENDP



_main PROC
ptl:
	call wczytaj_do_EAX_hex
	cmp eax, 6000
	jae ptl ;jesli 6000 <= to trzeba wpisac nowa liczbe
	call wyswietl_EAX
	cmp EAX, 0
	jne ptl
	push 0
	call _ExitProcess@4
_main ENDP
END
