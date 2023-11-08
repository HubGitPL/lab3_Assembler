;Zmodyfikować podprogram wyswietl_EAX_hex w taki sposób, by w
;wyświetlanej liczbie szesnastkowej zera nieznaczące z lewej strony zostały zastąpione
;spacjami.



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

wyswietl_EAX_hex PROC
    ; Wyświetlanie zawartości rejestru EAX w postaci szesnastkowej
    pusha ; Przechowanie rejestrów

    ; Rezerwacja 12 bajtów na stosie (poprzez zmniejszenie rejestru ESP) przeznaczonych na
    ; tymczasowe przechowanie cyfr szesnastkowych wyświetlanej liczby
    sub esp, 12
    mov edi, esp ; Adres zarezerwowanego obszaru

    ; Przygotowanie konwersji
    mov ecx, 8 ; Liczba obiegów pętli konwersji
    mov esi, 1 ; Indeks początkowy używany przy zapisie cyfr

    ; Pętla konwersji
    ptl3hex:
        ; Przesunięcie cykliczne (obrót) rejestru EAX o 4 bity w lewo
        rol eax, 4

        ; Wyodrębnienie 4 najmłodszych bitów i odczytanie z tablicy 'dekoder' odpowiadającej im cyfry
        mov ebx, eax
        and ebx, 0000000FH
        mov dl, dekoder[ebx]

        ; Przesłanie cyfry do obszaru roboczego
        mov [edi + esi], dl

        inc esi ; Inkrementacja modyfikatora

        loop ptl3hex ; Sterowanie pętlą

        ; Wytnij zera nieznaczące z lewej strony i zastąp spacjami
        mov esi, 1 ; Przywróć indeks początkowy
    usun_zera:
        cmp byte ptr [edi + esi], '0' ; Sprawdź, czy cyfra to zero
        jne skoncz
        mov byte ptr [edi + esi], ' ' ; Zastąp spacją
        inc esi
        loop usun_zera
    skoncz:

    ; Wpisanie znaku nowego wiersza przed i po cyfrach
    mov byte ptr [edi], 10
    mov byte ptr [edi + 9], 10

    ; Wyświetlenie przygotowanych cyfr
    push 10 ; 8 cyfr + 2 znaki nowej linii
    push edi ; Adres obszaru roboczego
    push 1 ; Ekran
    call __write

    ; Usunięcie ze stosu 24 bajtów, w tym 12 bajtów zapisanych przez 3 rozkazy push przed rozkazem call
    ; i 12 bajtów zarezerwowanych na początku podprogramu
    add esp, 24

    popa ; Odtworzenie rejestrów
    ret ; Powrót z podprogramu
wyswietl_EAX_hex ENDP


_main PROC
ptl:
	call wczytaj_do_EAX
	cmp eax, 6000
	jae ptl ;jesli 6000 <= to trzeba wpisac nowa liczbe
	call wyswietl_EAX_hex
	cmp EAX, 0
	jne ptl
	push 0
	call _ExitProcess@4
_main ENDP
END
