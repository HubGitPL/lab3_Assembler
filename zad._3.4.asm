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

wyswietl_EAX_hex	PROC
;wyświetlanie zawartości rejestru EAX w postaci szesnastkowej
	pusha ;przechowanie rejestrów

	;rezerwacja 12 bajtów na stosie (poprzez zmniejszenie rejestru ESP) przeznaczonych na 
	;tymczasowe przechowanie cyfr szesnastkowych wyświetlanej liczby
	sub	esp, 12
	mov edi, esp ;adres zarezerwowanego obszaru

	;przygotowanie konwersji 
	mov ecx, 8 ;liczba obiegów pętli konwersji
	mov esi, 1 ;indeks początkowy używany przy zapisie cyfr

	;pętla konwersji
	ptl3hex:

	;przesunięcie cykliczne (obrót) rejestru EAX o 4 bity w lewo w szczególności,
	;w peirwszym obiegu pętli bity nr 31-28 rejestru EAX zostaną przesunięte ja na pozycje 3 - 0
	rol	eax, 4

	;wyodrębnienie 4 najmłodszych bitów i odczytanie z tablicy 'dekoder' odpowiadającej im cyfry
	;w zapisie szesnastkowym 
	mov	ebx, eax ;kopiowanie EAX do EBX
	and ebx, 0000000FH ; zerowanie bitów 31-4 rej.EBX
	mov dl, dekoder[ebx] ;pobranie cyfry z tablicy

	;przesłanie cyfry do obszaru roboczego
	mov	[edi][esi], dl

	inc esi	;inkrementacja modyfikatora
	loop ptl3hex ;sterowanie pętlą

	;wpisanie znaku nowego wiersza przed i po cyfrach
	mov byte PTR [edi][0], 10
	mov byte PTR [edi][9], 10

	;wyświetlenie przygotowanych cyfr 
	push 10	;8cyfr+2znaki nowej lini
	push edi ;adres obszaru roboczego
	push 1 ;ekran
	call __write

	;usunięcie ze stosu 24 bajtów, w tym 12 bajtów zapisanych przez 3 rozkazy push przed rozkazem call
	;i 12 bajtów zarezerwowanych na początku podprogramu
	add esp, 24

	popa	;odtworzenie rejestrów
	ret ;powrót z podprogramu
wyswietl_EAX_hex	ENDP
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
