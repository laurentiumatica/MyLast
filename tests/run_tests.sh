#!/bin/bash

rosu='\033[0;31m'
rosu_bold='\033[1;31m'
verde='\033[0;32m'
verde_bold='\033[1;32m'
albastru='\033[0;34m'
albastru_bold='\033[1;34m'
nc='\033[0m'
bold='\033[1m'

cale_script="../mylast.sh"
contor_teste_reusite=0
contor_teste_esuate=0
contor_teste_rulate=0

ruleaza_test(){

	contor_teste_rulate=$((contor_teste_rulate+1))

	local test="$1"
	local comanda="$2"
	shift;shift
	local pattern="$@"

	echo -e "${albastru_bold}Se executa '$test': $comanda${nc}"
	echo -e "Pattern cautat: '$pattern'"

	if eval "$comanda" 2>&1 | grep -q "$pattern"; then
		echo -e "${verde_bold}PASS${nc}"
		contor_teste_reusite=$((contor_teste_reusite+1))
	else
		echo -e "${rosu_bold}FAIL${nc}"
		contor_teste_esuate=$((contor_teste_esuate+1))
	fi
	echo ""
}

if [[ ! -f "$cale_script" ]]; then
	echo -e "${rosu_bold}EROARE:${nc} Script-ul nu exista!"
	exit 1
fi

chmod +x "$cale_script"

echo -e "${bold}Test Script MyLast${nc}\n"

#ruleaza_test "ls test" "ls -la" "laurentiu"
#ruleaza_test "echo test" "echo hello world" "hello"
ruleaza_test "MyLast #0" "$cale_script -n 10" "Usage"

echo -e "${bold}Rezultate Finale${nc}\n"
echo -e "Teste rulate:  ${albastru}$contor_teste_rulate${nc}"
echo -e "Teste reusite: ${verde}$contor_teste_reusite${nc}"
echo -e "Teste esuate:  ${rosu}$contor_teste_esuate${nc}"
echo ""

if [[ "$contor_teste_reusite" == "$contor_teste_rulate" ]]; then
	echo -e "${verde_bold}Script-ul a rulat cu succes!${nc}"
	exit 0
else
	echo -e "${rosu_bold}Scriptul necesita interventie!${nc}"
	exit 1
fi

