#! /bin/bash
SQL_W='./pobierz_w.sql'
SQL_S='./pobierz_s.sql'
W_OUT='./wyposazenie.out'
S_OUT='./srodki.out'
W_TMP='./wyposazenie.tmp'
S_TMP='./srodki.tmp'
O_OUT='./ocs.out'
O_TMP='./ocs.tmp'
W_RAZEM='./razem'
CALOSC='./calosc.csv'
ZGODY='./zgody'

# pobieranie z WYPOSAZENIA i SRODKOW TRWALYCH
rm $W_RAZEM $S_TMP $S_OUT $W_TMP $W_OUT $O_TMP $O_OUT $ZGODY $CALOSC
isql-fb -i $SQL_W -o $W_OUT
isql-fb -i $SQL_S -o $S_OUT

# konwersja polskich znakow
iconv -f WINDOWS-1250 -t UTF-8 < $W_OUT > $W_TMP
iconv -f WINDOWS-1250 -t UTF-8 < $S_OUT > $S_TMP

# odchudzanie plikow
cat $W_TMP | grep -v 'NR_FABR\|====\|^$\|^#'  > $W_OUT
cat $S_TMP | grep -v ' MFP \|NR_FABR\|====\|^$\|^#'  > $S_OUT

sed -i 's/"/-/g' $W_OUT
sed -i 's/"/-/g' $S_OUT
sed -i 's/   \+/"/g' $W_OUT
sed -i 's/   \+/"/g' $S_OUT

exec 0< $W_OUT
while IFS='"'
# NR_SERYJNY NAZWA UMIEJSCOWIENIE OPIS ID_GRUPY ID ID_UMIEJSCOWIENIA
    read P1 P2 P3 P4 P5 P6 P7
do
#pomijamy puste linie i linie zaczynajace sie od #
    if [ "`echo ${W_OUT}|grep -v \"^#\|^$\"`" != "" ]
    then
	case ${#P6} in
	"1") P6_NEW=`echo W000000`$P6;;
	"2") P6_NEW=`echo W00000`$P6 ;;
	"3") P6_NEW=`echo W0000`$P6 ;;
	"4") P6_NEW=`echo W000`$P6 ;;
	"5") P6_NEW=`echo W00`$P6 ;;
	"*") P6_NEW=`echo BLAD`$P6 ;;
	esac
echo $P6_NEW%%$P2%%$P1%%$P3%%$P4 | sed 's/%%/\t/g' >> $W_RAZEM
    fi
done


exec 0< $S_OUT
while IFS='"'
# NR_SERYJNY NAZWA UMIEJSCOWIENIE OPIS KST ID ID_UMIEJSCOWIENIA
    read P1 P2 P3 P4 P5 P6 P7
do
#pomijamy puste linie i linie zaczynajace sie od #
    if [ "`echo ${S_OUT}|grep -v \"^#\|^$\"`" != "" ]
    then
	case ${#P6} in
	"1") P6_NEW=`echo S000000`$P6;;
	"2") P6_NEW=`echo S00000`$P6 ;;
	"3") P6_NEW=`echo S0000`$P6 ;;
	"4") P6_NEW=`echo S000`$P6 ;;
	"5") P6_NEW=`echo S00`+$P6 ;;
	"*") P6_NEW=`echo BLAD`+$P6 ;;
	esac
echo $P6_NEW%%$P2%%$P1%%$P3%%$P4 | sed 's/%%/\t/g' >> $W_RAZEM
    fi
done

# zaciagamy z OCS
mysql -B --column-names=0 -hlocalhost -uroot -p**** -e "SELECT hardware.LASTDATE, bios.SMANUFACTURER, bios.SMODEL, bios.SSN, hardware.NAME, hardware.IPADDR, hardware.IPSRC, accountinfo.TAG FROM ocsweb.hardware left join ocsweb.accountinfo on hardware.ID=accountinfo.HARDWARE_ID left join ocsweb.bios on hardware.ID=bios.HARDWARE_ID"  >> $O_OUT
mysql -B --column-names=0 -hlocalhost -uroot -p**** -e "SELECT hardware.LASTDATE, monitors.MANUFACTURER, monitors.CAPTION, monitors.SERIAL, hardware.NAME, hardware.IPADDR, hardware.IPSRC FROM ocsweb.monitors left join ocsweb.hardware on monitors.HARDWARE_ID=hardware.ID"  > $O_TMP
sed -i 's/$/\tMONITOR/' $O_TMP
sed -i 's/\t\t/\tZERO\t/g' $O_TMP
sed -i 's/\t\t/\tZERO\t/g' $O_TMP
grep -v cut -d$'\t' -f4 ./ocs.tmp 


cat $O_TMP >> $O_OUT
#exit 0
#mysql -B --column-names=0 -hlocalhost -uroot -p**** -e "SELECT hardware.LASTDATE, printers.NAME, printers.DRIVER, printers.PORT, hardware.NAME, hardware.IPADDR, hardware.IPSRC FROM ocsweb.printers left join ocsweb.hardware on printers.HARDWARE_ID=hardware.ID"  > $O_TMP
#sed -i 's/$/\tDRUKARKA/' $O_TMP
#cat $O_TMP | grep -v 'doPDF\|fax\|Fax\|XPS\|OneNote\|PDF' >> $O_OUT

# wyciągamy zgodności
while IFS=$'\t' read P1 P2 P3 P4 P5
# TAG NAZWA NR_SERYJNY UMIEJSCOWIENIE OPIS
do
    while IFS=$'\t' read R1 R2 R3 R4 R5 R6 R7 R8
# UPDATE PRODUCENT MODEL NR_SERYJNY HOST IP1 IP2 TAG
    do
    if test "$P3" = "$R4"
    then
echo $R1%%$R2%%$R3%%$R4%%$R5%%$R6%%$R7%%$R8%%$P1%%$P2%%$P3%%$P4%%$P5%%STAN_ZGODNY | sed 's/%%/\t/g' >> $CALOSC
echo $R4 >> $ZGODY
    fi
    done < $O_OUT
done < $W_RAZEM

# wyrzucamy zgodne i kopiujemy wszystko
while read SN
do
#echo $SN
sed -i "/$SN/d" $O_OUT
sed -i "/$SN/d" $W_RAZEM
done < $ZGODY

sed -i "s/$/\tP1\tP2\tP3\tP4\tP5\tOCS/" $O_OUT
sed -i "s/^/R1\tR2\tR3\tR4\tR5\tR6\tR7\tR8\t/" $W_RAZEM
sed -i "s/$/\tWYPOSAZENIE/" $W_RAZEM

cat $O_OUT >> $CALOSC
cat $W_RAZEM >> $CALOSC
#rm $W_RAZEM $S_TMP $S_OUT $W_TMP $W_OUT $O_TMP $O_OUT $ZGODY
rm $W_RAZEM $S_TMP $W_TMP $W_OUT $O_TMP $O_OUT $ZGODY

# pakowanie
zip -j $CALOSC.zip $CALOSC
uuencode $CALOSC.zip porownanie.zip | mail p.jakacki@capitalservice.pl -s "NOWY RAPORT PORÓWNIANIA OCS WYPOSAŻENIE"
uuencode $CALOSC.zip porownanie.zip | mail m.pianka@capitalservice.pl -s "NOWY RAPORT PORÓWNIANIA OCS WYPOSAŻENIE"
uuencode $CALOSC.zip porownanie.zip | mail k.szpond@capitalservice.pl -s "NOWY RAPORT PORÓWNIANIA OCS WYPOSAŻENIE"
