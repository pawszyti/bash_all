#!/bin/bash

tmp=/tmp/input.$$ # zmienna tymczasowa 

		dialog --menu "Co chcesz zrobic?" 12 30 4 1 'Reset hasła' \
		2 'Odblokuj konto' 3 '-- brak --' 4 '-- brak --' 2>$tmp

		sel=`cat $tmp`
		clear

					## MENU 1 - RESET HASŁA ##

	if test $sel -eq 1
	then
		dialog --title "Zmiana hasla" --inputbox "Podaj nazwe uzytkownika" 8 40 2>$tmp
		user=`cat $tmp`

			#funkcja odpowiedzialna sprawdzanie pola user
function reset_hasla {
			# jesli pole jest puste
	if [ -z "$user" ]
	then
	while [ -z "$user" ]
	do
		dialog --title "Zmiana hasła" --inputbox "Pole nie może być puste, podaj jeszcze raz nazwe uzytkownika" 8 40 2>$tmp
		user=`cat $tmp`
	done
		reset_hasla
		# jesli nie znaleziono uzytkownika
	elif [[ $( samba-tool user list | grep $user | wc -l ) < 1  ]] &> /dev/null
	then
		dialog --title "Informacja" --msgbox "Nie ma takiego użytkownika, spróbuj jeszcze raz" 7 40
		dialog --title "Zmiana hasła" --inputbox "Podaj nazwe użytkownika" 8 40 2>$tmp
		user=`cat $tmp`
		reset_hasla
			# jesli więcej niż jedna nazwa uzytkownika
	elif [[ $( samba-tool user list | grep $user | wc -l ) > 1  ]] &> /dev/null
	then
#		$( samba-tool user list | grep $user | wc -l) >$tmp
#		liczba=`cat $tmp`
		dialog --title "Informacja" --msgbox "Znaleziono więcej niż jedną nazwe użytkownika" 7 40
		dialog --title "Zmiana hasła" --inputbox "Podaj nazwe użytkownika" 8 40 2>$tmp
		user=`cat $tmp`
		reset_hasla
#		ilosc=1
#	for users in $( samba-tool user list | grep $user)
#	do
#		echo "$users" 
#		dialog --menu "Wybierz uzytkownika" 10 30  2 lista lisat2 start start2
#${liczba} ${ilosc} ${users}  
#		ilosc=+1
#	done
	fi
}
			# wywolanie funkcji reset hasla
reset_hasla
		samba-tool user list | grep $user >$tmp
		user=`cat $tmp`
		samba-tool user setpassword $user --must-change-at-next-login --newpassword=Capital1 &>$tmp
#		samba-tool user setpassword $user --newpassword=Capital1 &>$tmp
		alert=`cat $tmp`
		dialog  --title "Informacja" --msgbox "Użytkownik: $user - $alert" 7 40
		clear

						## MENU 2 ##
	elif test $sel -eq 2 
	then

	dialog --title "Zmiana hasla" --inputbox "Podaj nazwe uzytkownika" 8 40 2>$tmp
                user=`cat $tmp`

                        #funkcja odpowiedzialna sprawdzanie pola user
function wlacz_konto {
                        # jesli pole jest puste
        if [ -z "$user" ]
        then
        while [ -z "$user" ]
        do
                dialog --title "Zmiana hasła" --inputbox "Pole nie może być puste, podaj jeszcze raz nazwe uzytkownika" 8 40 2>$tmp
                user=`cat $tmp`
        done
                wlacz_konto
                # jesli nie znaleziono uzytkownika
        elif [[ $( samba-tool user list | grep $user | wc -l ) < 1  ]] &> /dev/null
        then
                dialog --title "Informacja" --msgbox "Nie ma takiego użytkownika, spróbuj jeszcze raz" 7 40
                dialog --title "Zmiana hasła" --inputbox "Podaj nazwe użytkownika" 8 40 2>$tmp
                user=`cat $tmp`
                wlacz_konto
                        # jesli więcej niż jedna nazwa uzytkownika
        elif [[ $( samba-tool user list | grep $user | wc -l ) > 1  ]] &> /dev/null
        then
                dialog --title "Informacja" --msgbox "Znaleziono więcej niż jedną nazwe użytkownika" 7 40
                dialog --title "Zmiana hasła" --inputbox "Podaj nazwe użytkownika" 8 40 2>$tmp
                user=`cat $tmp`
                wlacz_konto
        fi
}
		wlacz_konto
                samba-tool user list | grep $user >$tmp
                user=`cat $tmp`
                samba-tool user enable $user &>$tmp
                alert=`cat $tmp`
                dialog  --title "Informacja" --msgbox "Użytkownik: $user - $alert" 7 40
                clear

	elif test $sel -eq 3 
        then
		echo "sel jest trzy"
		clear

	else

		echo "sel jest cztery"
		clear	
	fi
