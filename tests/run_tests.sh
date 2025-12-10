#!/bin/bash

mylast_path="../mylast.sh"
teste_path="."
teste_rulate=0
teste_reusite=0
teste_esuate=0

ruleaza_test() {
	local nume_test="$1"
	local comanda="$2"
	local pattern="$3"

	echo "Rulez testul $nume_test"
	echo "Comanda $comanda"
	echo "Caut pattern $pattern"

	teste_rulate=$((teste_rulate+1))

	if eval "$comanda" | grep -q "$pattern"; then
		echo "Pass"
		teste_reusite=$((teste_reusite+1))
	else
		echo "Fail"
		teste_esuate=$((teste_esuate+1))
	fi
}

ruleaza_test "Test 1" "ls -la" "total"
ruleaza_test "Test 2" "echo hello" "hello"
ruleaza_test "Test 3" "$mylast_path -f file.log" "sshd"

echo "Teste rulate: $teste_rulate"
echo "Teste reusite: $teste_reusite"
echo "Teste esuate: $teste_esuate"

if [[ ! -f "$mylast_path" ]]; then #verificam daca exista script-ul
	echo "Eroare, my_last.sh nu exista la path-ul: $mylast_path"
	exit 1
fi
#daca exista, atunci il transformam in executabil
chmod +x "$mylast_path"
