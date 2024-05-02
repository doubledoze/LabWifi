#!/bin/bash

# Vérification si le script est exécuté avec sudo
if [ "$(id -u)" != "0" ]; then
    echo "Ce script doit être exécuté avec sudo."
    echo "Veuillez exécuter le script avec sudo."
    exit 1
fi

# Récupération des interfaces WLAN disponibles
interfaces=($(iw dev | awk '/Interface/{print $2}'))

# Filtrage des interfaces commençant par "wlan"
wlan_interfaces=()
for interface in "${interfaces[@]}"; do
    if [[ "$interface" == wlan* ]]; then
        wlan_interfaces+=("$interface")
    fi
done

# Affichage des interfaces WLAN disponibles
echo "Interfaces WLAN disponibles :"
echo "${wlan_interfaces[*]}" | tr ' ' '\n'


# Demande à l'utilisateur le range des interfaces à supprimer
read -p "Veuillez entrer le range des interfaces à supprimer (par exemple 1-40) : " range

# Séparation du range en début et fin
start=$(echo $range | cut -d'-' -f1)
end=$(echo $range | cut -d'-' -f2)

# Liste des interfaces à supprimer
interfaces_to_delete=()
for ((i=start; i<=end; i++)); do
    interface="wlan$i"
    if [[ " ${wlan_interfaces[@]} " =~ " ${interface} " ]]; then
        interfaces_to_delete+=("$interface")
    fi
done

# Affichage des interfaces à supprimer
echo "Interfaces à supprimer : ${interfaces_to_delete[*]}"

# Demande de confirmation à l'utilisateur pour supprimer les interfaces
read -p "Confirmez-vous la suppression de ces interfaces ? (oui/non) : " confirmation
if [ "$confirmation" != "oui" ]; then
    echo "Suppression annulée."
    exit 0
fi

# Suppression des interfaces
for interface in "${interfaces_to_delete[@]}"; do
    sudo iw dev "$interface" del
done

echo "Interfaces supprimées avec succès."
