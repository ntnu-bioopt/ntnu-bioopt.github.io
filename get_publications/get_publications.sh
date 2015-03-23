#!/bin/bash


function remove_publications(){
	filter_list=$1
	input_filename=$2
	output_filename=$3
	readarray -t publications < $filter_list
	endval=${#publications[@]}
	endval=$((endval-1))
	ns=$(seq 0 $endval)
	filter="contains(${publications[0]})"
	for n in $ns; do
		id=${publications[$n]}
		filter="$filter or contains($id)"
	done
	cat $input_filename | ./jq "[.[] | select(.id | $filter | not)]" > $output_filename
}



JSON_FILENAME="publications.json"
JSON_STRIPPED="publications_stripped.json"

years="2015 2014 2013 2012 2011 2010 2009 2008 2007 2006 2005 2004"
echo "[" > $JSON_STRIPPED
echo "{" >> $JSON_STRIPPED
echo "\"year\": null" >> $JSON_STRIPPED
echo "}" >> $JSON_STRIPPED

for year in $years; do
	#get publication data from cristin
	wget "http://cristin.no/ws/hentVarbeiderPerson?lopenr=44008&format=json&sortering=AAR_PERSON_TITTEL&hovedkategori=TIDSSKRIFTPUBL&fra=$year&til=$year" -O publications_${year}_tidsskriftpubl.json
	wget "http://cristin.no/ws/hentVarbeiderPerson?lopenr=44008&format=json&sortering=AAR_PERSON_TITTEL&hovedkategori=BOKRAPPORTDEL&fra=$year&til=$year" -O publications_${year}_bokrapportdel.json
	echo "," >> $JSON_STRIPPED
	echo "{" >> $JSON_STRIPPED
	echo "\"year\": \"$year\"," >> $JSON_STRIPPED
	echo "\"publications\":" >> $JSON_STRIPPED

	#combine tidsskriftspubl and bokrapportdel if there exists publications as bokrapportdel
	if [[ -s publications_${year}_bokrapportdel.json ]] ; then
		JSON_COMB="combined_${year}.json"
		echo "{" > $JSON_COMB
		echo "\"forskningsresultat\": [" >> $JSON_COMB
		cat publications_${year}_tidsskriftpubl.json | ./jq '.forskningsresultat' | tail -n +2 | head -n -1 >> $JSON_COMB
		echo "," >> $JSON_COMB
		cat publications_${year}_bokrapportdel.json | ./jq '.forskningsresultat' | tail -n +2 >> $JSON_COMB
		echo "}" >> $JSON_COMB
	else
		JSON_COMB="publications_${year}_tidsskriftpubl.json"
	fi

	#strip unecessary values
	JSON_TEMP="temp.json"
	cat $JSON_COMB | ./jq '[.forskningsresultat[] | {tittel: .fellesdata.tittel, ar: .fellesdata.ar, journal: .kategoridata.tidsskriftsartikkel.tidsskrift.navn, book: .kategoridata.bokRapportDel.delAv.forskningsresultat.fellesdata.tittel, serie: .fellesdata.rapportdata.publikasjonskanal.serie.navn, publisher: .fellesdata.rapportdata.publikasjonskanal.forlag.navn, doi: .kategoridata.tidsskriftsartikkel.doi, doi_bokrapport: .kategoridata.bokRapportDel.doi, volum: .kategoridata.tidsskriftsartikkel.volum, person: .fellesdata.person, id: .fellesdata.id, suppl: .fellesdata.id, suppltitle: .fellesdata.id, software: .fellesdata.id, github: .fellesdata.id, img: .fellesdata.id} | del(.person[].tilhorighet, .person[].harFodselsnummer, .person[].rekkefolgenr, .person[].id)]'  > $JSON_TEMP

	#filter away non-desired papers
	JSON_TEMP_2="temp2.json"
	remove_publications ignore_publications $JSON_TEMP $JSON_TEMP_2
	cat $JSON_TEMP_2 >> $JSON_STRIPPED	

	echo "}" >> $JSON_STRIPPED
done
echo "]" >> $JSON_STRIPPED

#add additional resources
readarray -t replacements < replacements.dat
endval=${#replacements[@]}
endval=$((endval-1))
ns=$(seq 0 $endval)
for n in $ns; do
	sedval=${replacements[$n]}
	$(sed -i -r -e "$sedval" $JSON_STRIPPED)
done

cat $JSON_STRIPPED | ./jq '.' > ../_data/publications.json
