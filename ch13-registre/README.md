# Chapitre 13 : Les bases de données registre (LevelDB, CouchDB)

# Partie A : LevelDB (section 13.5)

## 1. Prérequis

- Python 3.12 ; sous Linux, plyvel est offert précompilé, avec LevelDB inclus,
- sous macOS, la bibliothèque LevelDB de Homebrew (`brew install leveldb`),
- sous Windows, une distribution Ubuntu sous WSL 2 : plyvel n’est pas offert pour Windows.

Les exemples LevelDB ont été vérifiés avec plyvel 1.5.1 et LevelDB 1.22, sous Linux.

## 2. Installer

Placez-vous dans le dossier ch13-registre du dépôt, créez un environnement virtuel et installez plyvel :
```
cd bd-modernes/ch13-registre
python3.12 -m venv .venv && source .venv/bin/activate
pip install plyvel
```
Sous macOS, plyvel doit être compilé avec la bibliothèque LevelDB de Homebrew :
```
brew install leveldb
CFLAGS="-I$(brew --prefix)/include" \
  LDFLAGS="-L$(brew --prefix)/lib" pip install plyvel
```

## 3. Vérifier l’installation

La commande suivante affiche la version de LevelDB utilisée par plyvel :
```
python -c "import plyvel; print(plyvel.__leveldb_version__)"
```
Résultat attendu :
```
1.22
```
Sous macOS, la version affichée est celle de Homebrew.

## 4. Charger les données

Les exemples de cette section et l’étude de cas de la section 13.9 créent leurs propres bases dans /tmp ; le programme registre.py du dossier reprend l’étude de cas complète, falsification comprise.
```
python registre.py
```

## 5. En cas de problème

- **pip compile plyvel et échoue** : aucune version précompilée ne correspond à votre système ; installez LevelDB (Homebrew ou `sudo apt install libleveldb-dev`), ou utilisez Python 3.12 sous Linux,
- **« IO error: lock »** : un autre programme a déjà ouvert la même base ; LevelDB n’accepte qu’un seul processus à la fois.

## 6. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
rm -rf /tmp/registre /tmp/registre_vehicules
```

# Partie B : CouchDB (section 13.6)

## 1. Prérequis

- Docker Desktop, démarré,
- curl, présent par défaut sous macOS, Linux et Windows 10 ou plus récent.

Le dépôt utilise l’image couchdb:3.

## 2. Installer

Le fichier compose.yaml du dossier ch13-registre démarre un serveur CouchDB, nommé couchdb, sur le port 5984, avec l’administrateur admin et le mot de passe MotDePasse123 :
```
docker compose up -d
export C=http://admin:MotDePasse123@localhost:5984
```
Sans le dépôt, la commande suivante démarre le même serveur. Sous Windows, dans PowerShell, remplacez export par $env:C = "…" et utilisez curl.exe :
```
docker run -d --name couchdb -p 5984:5984 \
      -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=MotDePasse123 \
      couchdb:3
```

## 3. Vérifier l’installation

Le serveur répond par un document JSON de bienvenue :
```
curl $C/
```
Résultat attendu :
```
{"couchdb":"Welcome","version":"3.5.1", ...}
```
L’interface Web Fauxton est accessible à l’adresse http://localhost:5984/_utils.

## 4. Charger les données

La base vehicules est créée par les commandes de cette section. Les deux travaux pratiques (sections 13.10 et 13.11) ont leurs propres dépôts, avec leurs données et leurs programmes en Go ; il faut alors Go 1.22 ou plus récent et Git.

## 5. En cas de problème

- **curl répond 401** : l’utilisateur ou le mot de passe est incorrect dans la variable C,
- **le port 5984 est occupé** : un autre CouchDB s’exécute déjà, par exemple celui du travail pratique,
- **la réponse est 409 (conflit)** : c’est le comportement attendu lorsque la révision fournie n’est pas la révision courante.

## 6. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
docker compose down -v
```

## Travaux pratiques

- LevelDB (section 13.10) : `git clone https://github.com/rodrigueNTprojects/tp_levelDB_IND500.git`, puis suivez son README (Go 1.22 ou plus récent).
- CouchDB (section 13.11) : `git clone https://github.com/rodrigueNTprojects/couchdb-tp.git`, puis suivez son README.

Problèmes connus, constatés en compilant ces dépôts le 16 novembre 2026 :
- dans couchdb-tp, `cmd/cleanup/main.go` (ligne 98) utilise `node.Name`, qui n’existe pas ; remplacez-le par `node.Description` ;
- dans couchdb-tp, `pkg/conflict/resolver.go` ne compile pas tant que les trois zones « TODO » ne sont pas complétées : c’est voulu ;
- dans tp_levelDB_IND500, le message final de `bin/setup` propose `./bin/benchmark`, alors que l’outil s’appelle `bin/compare`.
