# Laboratoire Wi-Fi 

Ce laboratoire Docker simule un environnement disposant de plusieurs point d'accès Wi-Fi, disposant chacun de potentiels clients connectés et permet d'aborder les réseaux Wi-Fi de type WEP, WPA2, WPA3, WPA Entreprise. (Merci à WifiChallengeLab)

La simulation s'effectue grâce à `hwsim` et permet de créer des interfaces Wi-Fi virtuelles, ces interfaces sont créées sur la machine hôte, le lancement du lab va créer beaucoup d'interface sur votre machine hôte mais rassurez-vous, une fois le lab éteint, la désactivation du module `mac80211_hwsim` entrainera automatiquement la suppression des interfaces virtuelles créées.

L'ensemble des activités de ce TP devront se réaliser avec l'interface virtuelle `wlan0` que vous passerez en mode monitor sauf si mention contraire dans les commandes fournies, et vous répondrez aux questions de ce TP en vous appuyant sur le cours déjà réalisé ensemble qui contient la majeure partie des commandes utiles (autrement c'est fourni ici).

N'oubliez pas de travailler organisé, créez un répertoire de travail, notamment pour stocker vos captures réseaux.

# Reconnaissance

Passez l'interface `wlan0` en mode `monitor` et énumérez la liste des réseaux Wi-Fi, pour cette première action je vous offre les commandes :
```bash
sudo airmon-ng start wlan0
sudo airodump-ng wlan0mon --manufacturer --wps --band abg
```

Répondez aux questions suivantes :
1. Combien de réseau Wi-Fi identifiez-vous ?
2. Quels sont les différents types de chiffrement présents ?
3. Quels sont les réseaux Wi-Fi qui fonctionnent en 5 GHz ?
4. Quel est l'adresse MAC de wifi-IT ?
5. A quel réseau est connecté le client `28:6C:07:6F:F9:44` ?
6. Quel sont les réseaux que recherche le client `78:C1:A7:BF:72:46` (probes) ?

# Identification du réseau caché

Nous avons vu ensemble que certains réseaux Wi-Fi pouvaient ne pas diffuser leur SSID et surtout que ce n'était pas une sécurité car il était toujours possible d'identifier le SSID d'un point d'accès.

Dans ce cas, il est possible d'utiliser l'outil `mdk4` pour trouver le SSID d'un point d'accès, cependant mdk4 s'appuie sur une Wordlist pour essayer de trouver le SSID, nous allons donc nous appuyer sur la wordlist `Rockyou` que nous allons adapter car les réseaux Wi-Fi commencent tous par `wifi-` comme on a pu le voir lors de la reconnaissance.
Ensuite nous devons définir le bon canal sur `wlan0mon` car mdk4 ne change pas tout seul de canal, à vous d'identifier le bon numéro de canal correspondant au réseau Wi-Fi invisible.
Enfin il faudra lancer MDK4. Pensez à remplacer les valeurs indiquées entre {}.

```bash
wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
cat rockyou.txt | awk '{print "wifi-" $1}' > wifi-rockyou.txt
sudo iwconfig wlan0mon channel {channelnumber}
sudo mdk4 wlan0mon p -t {bssid} -f wifi-rockyou.txt
```

7. Quel est le SSID du point d'accès Wi-Fi invisible ?

# Investigation du réseau Wi-Fi caché (OPN)

Vous connaissez le SSID, le réseau Wi-Fi ne demande pas de clé (authentification OPN), connectez-vous au réseau Wi-Fi soit en utilisant votre interface graphique (utilisez wlan2) 
Si vous rencontrez un soucis de connexion avec votre interface graphique, utilisez `wpa_supplicant` en vous référant à l'annexe.

Lorsque vous avez obtenu une adresse IP, accédez à l'adresse `192.168.16.1` (HTTP) et tentez de vous loguer.

8. Quel est le flag obtenu ?

# Investigation du wifi-guest

Dans la reconnaissance nous avons identifié un réseau `wifi-guest` qui ne possède pas de mot de passe, connectez-vous à ce réseau toujours en utilisant `wlan2` et accédez à l'adresse (HTTP) 192.168.10.1

C'est un portail captif mais à priori impossible de le contourner... Dans la phase de reconnaissance, vous avez probablement pu constater que quelqu'un était déjà connecté à ce réseau. Si on essayait d'usurper son adresse MAC pour contourner le portail captif ? Si éventuellement lors de la phase de reconnaissance vous ne trouvez pas le client connecté, affinez votre capture `airodump-ng` pour limiter au `BSSID` correspondant à `wifi-guest`.

Déconnectez-vous du réseau Wi-Fi, modifiez votre adresse MAC en utilisant l'interface graphique, sous les paramètres de `wifi-guest`, dans l'onglet `Identité` vous pouvez changer votre adresse MAC dans le champ `Adresse clonée`, si cela ne fonctionne pas, documentez-vous sur `macchanger` et tentez avec cet outil. Ensuite reconnectez-vous au Wi-Fi et accédez de nouveau au portail captif.

Si vous vous êtes bien débrouillé, vous devriez accéder à la page de login du routeur. Cependant nous n'avons pas les accès... Enfin si, mais pas les bons...
Pour récupérer les bons accès, il va falloir de nouveau sniffer le réseau comme à l'étape `Reconnaissance` mais cette fois-ci en sauvegardant les données dans un fichier de capture, cette capture nous allons la réaliser avec notre interface en mode monitor `wlan0mon`, cette interface n'est pas connectée au réseau `wifi-guest` et pourtant nous allons voir le flux `HTTP` passer.

9. Pourquoi le flux HTTP est visible alors que notre interface n'est pas connectée au réseau ?
10. Quel est le flag obtenu une fois connecté à l'interface du routeur ?

# Notre bon vieux WEP

Obtenez la clé de `wifi-old`, la clé est au format hexadécimal. Soit vous utilisez la méthode documentée dans le cours (méthode manuelle), soit vous utilisez une alternative que je ne vous ai pas présenté c'est l'outil `bessides-ng` dont je vous laisse le soin de vous documenter.

11. Quel est la clé Wi-Fi de `wifi-old` ?

Pour vous assurer que la clé fonctionne, vous pouvez vous connecter au réseau et tenter d'accéder à http://192.168.19.1/

# Un petit tour sur du WPA PSK

Le réseau `wifi-mobile` est protégé par une clé de type WPA PSK (Pre-Shared Key), obtenez la clé en effectuant une attaque de `deauth` permettant de désauthentifier un client légitime, afin de capturer le `handshake`, cassez le handshake avec la wordlist `rockyou` :
`aircrack-ng capture.cap -w rockyou.txt`

11. Quel est la clé Wi-Fi du réseau `wifi-mobile` ?

Avec le handshake et la clé Wi-Fi il est possible de déchiffrer à la volée le trafic Wi-Fi sans se connecter au réseau, pour cela on peut utiliser l'outil `airdecap-ng` :
`airdecap-ng -e wifi-mobile -p {password} capture.cap`

Laissez tourner cette capture quelques minutes puis ouvrez le fichier généré `capture-dec.cap`, celui-ci contient l'ensemble du trafic déchiffré, si vous regardez bien vous devriez y trouver un `cookie`, notez-le bien !

Connectez-vous au réseau Wi-Fi, essayez d'accéder à http://192.168.2.1/ puis insérez le cookie dans le stockage de votre navigateur, actualisez la page et constatez le flag.

12. Quel est le flag obtenu sur l'interface 192.168.2.1 ?

13. Est-ce que nous sommes sur un réseau Wi-Fi disposant d'isolation des clients ?

14. Identifiez les autres clients connectés (leurs adresses IP et ports ouverts), trouvez un flag.

# Un réseau inexistant

Dans la phase de `reconnaissance` on peut constater que certains clients diffusent des `probes` au nom de `wifi-offices` cependant nous ne captons pas ce réseau. Mais on peut potentiellement obtenir la clé de ce réseau en créant un faux point d'accès avec l'outil `hostapd-mana` et ainsi obtenir le handshake lorsque le client va tenter de s'y connecter, puis tenter de casser le handshake.

Créez un fichier `hostapd.conf` :
```
interface=wlan1
driver=nl80211
hw_mode=g
channel=1
ssid=wifi-offices
mana_wpaout=hostapd.hccapx
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
wpa_passphrase=12345678
```

Puis lancez la commande `hostapd-mana hostapd.conf` mais faites un `CTRL+C` lorsque vous verrez le terme `AP-STA-POSSIBLE-PSK-MISMATCH`, le fichier contenant le handshake sera sauvegardé sous le nom `hostapd.hccapx`, tentez de le casser avec `hashcat` :
`hashcat -a 0 -m 2500 hostapd.hccapx rockyou.txt --force`

Si cela ne fonctionne pas avec le mode `2500`, vous pouvez convertir le hash au format `22000` et le casser à nouveau avec hashcat :
```
hcxhash2cap --hccapx=hostapd.hccapx -c aux.pcap
hcxpcapngtool aux.pcap -o hash.22000
sudo hashcat -a 0 -m 22000 hash.22000 rockyou.txt --force
```

15. Quel est la clé du réseau Wi-Fi `wifi-offices` ?

# A la découverte de WPA3 (SAE)

Sur les réseaux en WP3 il est possible de brute-forcer jusqu'à trouver le mot de passe, en utilisant l'outil `wacker`. 
L'outil est disponible ici : https://github.com/blunderbuss-wctf/wacker
Je vous aide, voici la démarche :
```
./wacker.py --wordlist rockyou.txt --ssid wifi-management --bssid F0:9F:C2:11:0A:24 --interface wlan2 --freq 2462
```

16. Quel est le mot de passe du réseau `wifi-management` ?

# Attaque downgrade sur WPA3 SAE

Si un réseau de type WPA3 SAE possède un client connecté et capable de fonctionner en WPA2 PSK/WPA3 SAE alors il est possible de faire une attaque Downgrade sur le client, en le forçant à se connecter à un `RogueAP` monté pour l'occasion et paramétré en WPA2, cela permettra d'obtenir un `handshake` à cracker (comme avec wifi-offices). Cependant il faut aussi que le point d'accès supporte la double sécurité PSK/SAE.

Avec `airodump-ng` on peut obtenir cette information en consultant la colonne `Authentication` qui mentionne pour le réseau `wifi-IT` l'information `SAE PSK`.

Donc pour mettre en oeuvre cette attaque, nous allons créer un faux point d'accès Wi-Fi, l'objectif étant de désauthentifier le client légitime pour qu'il se reconnecte à notre point d'accès Wi-Fi, cependant sur WPA3 il existe des protections contre la déauth, encore faut-il que ces protections soient activées...

On peut vérifier cette information en consultant une capture réseau (pcap) réalisée avec `airodump-ng` et en recherchant une trame de type `Beacon`, si on déroule la couche `IEEE 802.11 Wireless Management`, sous `Tag: RSN Information`, dans `RSN Capabilities` on peut vérifier les deux éléments suivants : 
```
Management Frame Protection Required : False
Management Frame Protection Capable : False
```
Dans notre cas, les deux flags sont définis à False, c'est ce que l'on appelle `802.11w`, donc le réseau WPA3 n'est pas protégé contre les déauth.

Donc créez un faux point d'accès Wi-Fi en utilisant `hostapd-mana`, pour cela créez un fichier `hostapd-sae.conf` :
```
interface=wlan1
driver=nl80211
hw_mode=g
channel=11
ssid=wifi-IT
mana_wpaout=hostapd-management.hccapx
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
wpa_passphrase=12345678
```
Démarrez le point d'accès Wi-Fi avec la commande : `hostapd-mana hostapd-sae.conf`
En parallèle, déauthentifiez le client légitime (à vous de remplir les valeurs que vous pouvez obtenir avec airodump-ng) :
```
iwconfig wlan0mon channel 11
aireplay-ng wlan0mon -0 0 -a {BSSID}  -c {@MAC_CLIENTLEGITIME}
```
Pensez à arrêter la déauth pour que le client puisse se reconnecter cette fois à votre RogueAP, dès que le client se sera connecté à votre rogueAP vous verrez l'information `Captured a WPA/2 hanshake from ...`, dès lors vous pouvez stopper le rogueAP et casser le handshake. Même démarche qu'avec le point d'accès `wifi-offices` et l'outil `hashcat`.

17. Quel est la clé Wi-Fi du réseau `wifi-IT` ?

# WPA Enterprise (MGT) - Reconnaissance

Nous avons vu WEP, WPA, WPA2, WPA3... maintenant penchons nous sur le `WPA Enterprise`. Les fameux réseaux proposant une authentification par couple id/pass, par certificat ou encore par carte à puce. Et commençons par une simple reconnaissance.

Dans les réseaux MGT, les utilisateurs disposant d'une mauvaise configuration peuvent envoyer leur identité (nom d'utilisateur) en clair avant de mettre en oeuvre un tunnel TLS, donc avec `airodump-ng` nous pouvons obtenir passivement cette information. Pour cela, il suffit d'utiliser `airodump-ng` sur le bon canal et d'attendre que les clients se connectent.

Cette étape est très intéressante car elle permet d'obtenir passivement des noms d'utilisateur d'un environnement Active Directory si le PA Wi-FI est un PA réalisant son authentification via AD.

Pour découvrir un nom d'utilisateur, réalisez une capture avec Airodump-ng sur le bon canal en utilisant la commande suivante : 
`airodump-ng wlan0mon -w canal44 -c 44 --wps`
Laissez tourner la capture quelques minutes puis ouvrez le fichier de capture avec Wireshark et partez à la recherche d'un identifiant (filtrez sur le protocole EAP).

19. Quels sont les SSIDs disposant d'une authentification 802.1X (alias Radius ou MGT) ?
18. Quels sont les noms de domaine que vous identifiez ?
19. Quels sont les noms d'utilisateurs ?

# WPA Enterprise (MGT) - Le tunnel TLS

Pour créer le tunnel TLS entre le réseau MGT et un client, l'AP envoie le certificat au client en texte clair, de sorte que n'importe qui peut le voir. Cette information peut être utile pour créer un faux certificat avec les mêmes champs dans une attaque RogueAP ou pour obtenir des informations sur le domaine de l'entreprise, les adresses mail internes ou d'autres informations pertinentes sur l'AP.

Si la capture réalisée à l'étape précédente a été suffisamment longue, vous devriez trouver dans votre interface Wireshark des paquets de type `TLSv1.2` indiquant `Server Hello, Server Key Exchange...`, si ce n'est pas le cas, relancez une nouvelle capture plus longue.

Fouillez le paquet à la recherche de l'adresse mail renseignée dans le certificat serveur.

19. Quel est l'adresse mail indiquée dans le certificat **serveur** ?

# WPA Enterprise (MGT) - Identification des méthodes d'authentification supportées

Une fois que nous avons obtenu un nom d'utilisateur valide (pas anonyme), il est possible d'énumérer la liste des méthodes d'authentification EAP que le point d'accès supporte, cela peut-être fait via l'outil `EAP_buster` disponible à l'adresse : https://github.com/blackarrowsec/EAP_buster

Recherchez donc toutes les méthodes supportées par le point d'accès `wifi-global` avec l'utilisateur identifié aux étapes précédentes : 

`bash ./EAP_buster.sh "wifi-global" "DOMAINE\User" wlan2`

N'hésitez pas à répéter l'opération si vous n'obtenez pas de résultat concluant.

20. Quel est la/les méthodes supportées par le point d'accès Wi-Fi ?

# WPA Enterprise (MGT) - À l'attaque !

Pour attaquer un client de confiance sur un réseau MGT, nous devons créer un RogueAP avec le même ESSID et la même configuration, mais avec un certificat auto-signé, de préférence avec les mêmes données que le vrai certificat serveur, au cas où le client vérifierait manuellement le certificat. Pour ce faire, vous pouvez utiliser `eaphammer` disponible à l'adresse : https://github.com/s0lst1c3/eaphammer

EAPHammer va permettre la création de notre RogueAP :
```
python3 ./eaphammer --cert-wizard
python3 ./eaphammer -i wlan3 --auth wpa-eap --essid wifi-corp --creds --negotiate balanced
```
Et en parallèle il va falloir déconnecter les clients légitimes via leurs adresses MAC (attaque déauth), pour cela je vous donne son l'adresse MAC `64:32:A8:BA:6C:41` du premier client légitime. Enfin avec `airodump-ng` nous avons pu constater qu'il y avait deux point d'accès `wifi-corp`, il faut donc effectuer l'attaque contre les deux PA sinon le client qui se déconnecte d'un AP pourra se reconnecter au second au lieu de se connecter à notre RogueAP :

Attaque vers `wifi-corp` premier du nom : 
```
iwconfig wlan0mon channel 44
aireplay-ng -0 0 -a {@MAC_AP_WIFICORP1} wlan0mon -c 64:32:A8:BA:6C:41
```

Attaque vers `wifi-corp` second du nom (pensez à passer wlan1 en monitor car nous ne l'avons pas utilisé tel quel jusqu'à présent) :
```
iwconfig wlan1mon channel 44
aireplay-ng -0 0 -a {@MAC_AP_WIFICORP1} wlan1mon -c 64:32:A8:BA:6C:41
```

Ces deux attaques doivent être simultanées.

Si tout s'est bien passé, sur `EAPHammer` vous devriez constater le message `SSL: SSL3 alert: read (remote end reported an error):fatal:unknown CA`, en effet cela ne fonctionne pas, ce client a détecté que la CA (Certificate Authority) n'était pas reconnue de fait la connexion ne s'est pas initiée...

Répétez la même opération avec le second client légitime : `64:32:A8:07:6C:40`

Et là ! Jackpot, vous obtenez les informations d'identification MSCHAPv2, hash NETNTLM... Plus qu'à essayer de les casser, récupérez dans le log le hash de type `hashcat NETNTLM:` et stockez le dans un fichier `hashcat.5500` puis : 
```
hashcat -a 0 -m 5500 hashcat.5500 rockyou.txt --force
```

21. Quel est le nom d'utilisateur et le mot de passe obtenu via cette attaque ?

# WPA Enterprise (MGT) - Attaque Relais du challenge NETNTLM

# WPA Enterprise (MGT) - Phishing + RogueAP / Responder + RogueAP

# WPA Enterprise (MGT) - Récupération de la CA légitime et utilisation sur un RogueAP

# Annexe wpa_supplicant 

Créez un fichier `wifi.conf` avec le contenu suivant, remplacez `$SSID` par la valeur que vous avez trouvé à l'étape précédente :

```
network={
	ssid="$SSID"
	key_mgmt=NONE
	scan_ssid=1
}
```

Utilisez `wpa_supplicant` pour vous connecter au Wi-Fi :
`sudo wpa_supplicant -Dnl80211 -iwlan2 -c wifi.conf`

Et dans un nouveau terminal, demandez une IP avec dhclient :
`sudo dhclient wlan2 -v`

