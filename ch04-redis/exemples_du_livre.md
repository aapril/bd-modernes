# Chapitre 4 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 4.3 Installer Redis

> Depuis Redis 8, l’image officielle redis contient aussi le stockage de documents JSON et le moteur de requêtes, qui étaient auparavant distribués dans l’image redis-stack. Le fichier compose.yaml du dossier ch04-redis démarre le serveur, nommé redis, sur le port 6379, et l’outil graphique Redis Insi…

```
% cd bd-modernes/ch04-redis
% docker compose up -d
% docker exec -it redis redis-cli
```

> Sans le dépôt, les commandes suivantes démarrent les mêmes conteneurs :

```
% docker run -d --name redis -p 6379:6379 redis:8.10
% docker run -d --name redisinsight -p 5540:5540 \
       redis/redisinsight:latest
```

> Le serveur doit répondre PONG, et la commande JSON.SET doit réussir, ce qui confirme la présence du module JSON :

```
% docker exec -it redis redis-cli PING
% docker exec -it redis redis-cli JSON.SET essai '$' '{"ok":1}'
```

> Le résultat attendu est le suivant :

```
PONG
OK
```

> Les commandes des sections 4.4 et 4.5 créent elles-mêmes leurs clés. L’étude de cas de la section 4.7 lit la base club du chapitre 2 : démarrez aussi le conteneur pg-club, puis installez les dépendances Python du dossier :

```
% python3 -m venv .venv && source .venv/bin/activate
% pip install -r requirements.txt
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% docker exec -it redis redis-cli FLUSHALL   # vide la base
% docker compose down
```


## 4.4.1 Les chaînes (strings)

> La chaîne est le type le plus simple : une suite d’octets d’au plus 512 Mo, qui peut contenir du texte, un nombre, un document JSON sérialisé ou même une image. Les commandes de base sont SET, GET et DEL :

```
> SET club:nom "Club Sportif de Montréal"     # OK
> GET club:nom                   # "Club Sportif de Montréal"
> DEL club:nom                   # (integer) 1
```

> Lorsqu’une chaîne contient un entier, les commandes INCR, DECR et INCRBY le modifient de façon atomique. Deux clients qui incrémentent le même compteur en même temps ne perdront jamais d’incrément, ce qui n’est pas le cas si le programme lit la valeur, l’augmente puis l’écrit :

```
> INCR club:visites:2023-09-14        # (integer) 1
> INCRBY club:visites:2023-09-14 5      # (integer) 6
```

> Toute clé peut recevoir une durée de vie. À l’expiration, Redis supprime la clé automatiquement. L’option EX de SET fixe la durée en secondes, et l’option NX n’écrit la clé que si elle n’existe pas déjà, ce qui permet de réaliser un verrou simple :

```
> SET code:verif:27 "481920" EX 300   # OK, expire dans 5 minutes
> TTL code:verif:27                   # (integer) 297
> SET verrou:rapport "srv-2" NX EX 30  # OK si personne ne l’a
> SET verrou:rapport "srv-3" NX EX 30  # (nil), déjà pris
```


## 4.4.2 Les tables de hachage (hashes)

> Une table de hachage associe des champs à des valeurs sous une même clé. C’est la structure naturelle pour représenter un objet, par exemple un membre du Club Sportif. Contrairement à une chaîne contenant du JSON, chaque champ peut être lu ou modifié individuellement :

```
> HSET membre:27 prénom Julie nom Tremblay cp H3C1K3
                                 # (integer) 3
> HGET membre:27 prénom           # "Julie"
> HINCRBY membre:27 nb_réservations 1   # (integer) 1
> HGETALL membre:27     # les champs et leurs valeurs
```


## 4.4.3 Les listes (lists)

> Une liste est une séquence ordonnée de chaînes, réalisée comme une liste doublement chaînée : l’ajout et le retrait aux deux extrémités se font en temps constant. On l’utilise pour garder les derniers éléments d’un historique ou comme file d’attente simple. LPUSH ajoute au début, RPOP retire à la fi…

```
> LPUSH membre:27:historique "tennis" "squash" "piscine"
> LRANGE membre:27:historique 0 -1   # piscine, squash, tennis
> LTRIM membre:27:historique 0 9     # garder les 10 plus récents
```


## 4.4.4 Les ensembles (sets)

> Un ensemble contient des chaînes uniques, sans ordre. Redis calcule directement l’union, l’intersection et la différence de plusieurs ensembles, ce qui est utile pour les étiquettes, les relations d’abonnement ou les recommandations :

```
> SADD activité:tennis:inscrits 27 31 44
> SADD activité:squash:inscrits 27 44 58
> SINTER activité:tennis:inscrits activité:squash:inscrits  # 27, 44
> SISMEMBER activité:tennis:inscrits 58   # (integer) 0
```


## 4.4.5 Les ensembles triés (sorted sets)

> Un ensemble trié associe à chaque membre un score numérique et garde les membres triés selon ce score. C’est la structure qui a rendu Redis célèbre pour les tableaux de classement : l’insertion, la mise à jour d’un score et la lecture du rang se font en temps logarithmique, même avec des millions de…

```
> ZADD classement:2023 12 "membre:27" 30 "membre:44" 7 "membre:58"
> ZINCRBY classement:2023 1 "membre:58"   # "8"
> ZRANGE classement:2023 0 2 REV WITHSCORES   # les 3 premiers
> ZREVRANK classement:2023 "membre:27"     # (integer) 1, 2e place
```


## 4.4.6 Les flux (streams)

> Un flux est un journal d’événements dans lequel on ne peut qu’ajouter. Chaque entrée reçoit un identifiant basé sur l’heure et contient un ensemble de champs. Contrairement à une liste, un flux conserve les messages après leur lecture, et plusieurs groupes de consommateurs peuvent le lire chacun à l…

```
> XADD flux:résa * membre 27 activité 3 action "créée"
                        # "1794804737422-0", par exemple
> XGROUP CREATE flux:résa compta 0
> XREADGROUP GROUP compta t1 COUNT 10 STREAMS flux:résa >
> XACK flux:résa compta 1794804737422-0  # (integer) 1
```


## 4.5.2 Transactions

> Les commandes MULTI et EXEC regroupent plusieurs commandes qui seront exécutées d’un seul bloc, sans qu’aucun autre client ne puisse s’intercaler. La commande WATCH ajoute un contrôle de concurrence optimiste : si une clé surveillée est modifiée par un autre client avant EXEC, la transaction est ann…

```
> SET activité:3:places 1
> WATCH activité:3:places
> GET activité:3:places      # "1" : il reste une place
> MULTI
> DECR activité:3:places
> SADD activité:3:inscrits 58
> EXEC   # (nil) si un autre client a modifié la clé
```


## 4.7 Étude de cas : accélérer le Club Sportif avec Redis

> Le site Web du Club Sportif interroge la BD PostgreSQL du chapitre 2 à chaque affichage de la page des activités. Avec l’augmentation du nombre de membres, cette page est devenue lente aux heures de pointe. Nous allons utiliser Redis pour trois besoins : mettre en cache la liste des activités, affic…

```
% pip install redis "psycopg[binary]"
```


## 4.7.1 Un cache de type « cache-aside »

> La connexion à PostgreSQL est ouverte en mode autocommit : chaque requête est validée immédiatement, ce qui évite de laisser une transaction ouverte entre deux lectures du cache.

```
import json, os
import psycopg, redis

r = redis.Redis(host="localhost", port=6379,
                decode_responses=True)
pg = psycopg.connect(os.environ["DATABASE_URL"],
                     autocommit=True)
CLE = "club:activités:liste"

def liste_activités() -> list[dict]:
    en_cache = r.get(CLE)
    if en_cache is not None:              # succès de cache
        return json.loads(en_cache)
    lignes = [{"id": i, "nom": n, "coût": float(c)}
              for i, n, c in pg.execute(       # échec
                  "SELECT numéro_activité, nom, "
                  "coût_pour_membre FROM activités "
                  "ORDER BY nom")]
    r.set(CLE, json.dumps(lignes), ex=600)  # 10 minutes
    return lignes
```

> La durée de vie garantit que le cache se rafraîchit de lui-même. Lorsqu’une activité est modifiée, il est toutefois préférable d’invalider le cache immédiatement plutôt que d’attendre l’expiration :

```
def modifier_coût(id_activité: int, coût: float) -> None:
    pg.execute("UPDATE activités SET coût_pour_membre = %s"
               " WHERE numéro_activité = %s",
               (coût, id_activité))
    r.delete(CLE)          # la prochaine lecture rechargera
```


## 4.7.2 Un classement en temps réel

> Le club veut afficher sur sa page d’accueil les dix membres qui ont fait le plus de réservations ce mois-ci. Calculer ce classement en SQL à chaque affichage demanderait un GROUP BY sur toute la table des réservations. Avec un ensemble trié, il suffit d’incrémenter le score du membre à chaque réserv…

```
def enregistrer_réservation(membre: int, mois: str) -> None:
    # ... insertion dans PostgreSQL ...
    r.zincrby(f"classement:{mois}", 1, f"membre:{membre}")

def dix_premiers(mois: str):
    return r.zrange(f"classement:{mois}", 0, 9,
                    desc=True, withscores=True)
```


## 4.7.3 Un limiteur de débit

> Enfin, pour protéger l’API de réservation, on limite chaque membre à 20 appels par minute. La technique de la fenêtre fixe utilise un compteur par membre et par minute ; la transaction (un pipeline exécuté avec MULTI et EXEC) garantit que l’incrément et l’expiration sont appliqués ensemble :

```
import time

def autorisé(membre: int, limite: int = 20) -> bool:
    minute = int(time.time() // 60)
    clé = f"débit:{membre}:{minute}"
    with r.pipeline(transaction=True) as p:
        p.incr(clé)
        p.expire(clé, 60)
        nb, _ = p.execute()
    return nb <= limite
```
