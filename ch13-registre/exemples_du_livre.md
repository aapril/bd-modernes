# Chapitre 13 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 13.3.1 Les fonctions de hachage cryptographiques

> En Python, le module standard hashlib calcule ces empreintes. Le programme suivant affiche les 16 premiers caractères de chacune :

```
import hashlib

for nom in [b"Julie", b"julie"]:
    print(nom, hashlib.sha256(nom).hexdigest()[:16])

b'Julie' abaa68c541efe0fc
b'julie' b025079c90813d46
```


## 13.5 LevelDB, un magasin clé-valeur embarqué

> Placez-vous dans le dossier ch13-registre du dépôt, créez un environnement virtuel et installez plyvel :

```
% cd bd-modernes/ch13-registre
% python3.12 -m venv .venv && source .venv/bin/activate
% pip install plyvel
```

> Sous macOS, plyvel doit être compilé avec la bibliothèque LevelDB de Homebrew :

```
% brew install leveldb
% CFLAGS="-I$(brew --prefix)/include" \
  LDFLAGS="-L$(brew --prefix)/lib" pip install plyvel
```

> La commande suivante affiche la version de LevelDB utilisée par plyvel :

```
% python -c "import plyvel; print(plyvel.__leveldb_version__)"
```

> Le résultat attendu est le suivant :

```
1.22
```

> Les exemples de cette section et l’étude de cas de la section 13.9 créent leurs propres bases dans /tmp ; le programme registre.py du dossier reprend l’étude de cas complète, falsification comprise.

```
% python registre.py
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% rm -rf /tmp/registre /tmp/registre_vehicules
```

> En Python, la bibliothèque plyvel donne accès à LevelDB :

```
import plyvel

db = plyvel.DB("/tmp/registre", create_if_missing=True)
db.put(b"vin:5YJ3E1EA7JF000001", b'{"proprietaire": "Julie"}')
print(db.get(b"vin:5YJ3E1EA7JF000001"))

with db.write_batch() as lot:          # atomique
    lot.put(b"tx:000001", b"...")
    lot.put(b"tx:000002", b"...")

for cle, valeur in db.iterator(prefix=b"tx:"):
    print(cle, valeur)
```


## 13.6 CouchDB, une BD documents à révisions

> Le fichier compose.yaml du dossier ch13-registre démarre un serveur CouchDB, nommé couchdb, sur le port 5984, avec l’administrateur admin et le mot de passe MotDePasse123 :

```
% docker compose up -d
% export C=http://admin:MotDePasse123@localhost:5984
```

> Sans le dépôt, la commande suivante démarre le même serveur. Sous Windows, dans PowerShell, remplacez export par $env:C = "…" et utilisez curl.exe :

```
% docker run -d --name couchdb -p 5984:5984 \
      -e COUCHDB_USER=admin -e COUCHDB_PASSWORD=MotDePasse123 \
      couchdb:3
```

> Le serveur répond par un document JSON de bienvenue :

```
% curl $C/
```

> Le résultat attendu est le suivant :

```
{"couchdb":"Welcome","version":"3.5.1", ...}
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% docker compose down -v
% curl -X PUT $C/vehicules
% curl -X PUT $C/vehicules/5YJ3E1EA7JF000001 \
       -H "Content-Type: application/json" \
       -d '{"marque": "Tesla", "annee": 2012,
            "proprietaire": "Julie"}'
{"ok":true,"id":"5YJ3E1EA7JF000001","rev":"1-7c4a..."}
```

> Pour modifier le document, il faut fournir la révision reçue : remplacez 1-7c4a… par la valeur du champ rev de la réponse précédente, sinon CouchDB répond par l’erreur 409. CouchDB conserve la nouvelle version sous la révision 2 :

```
% curl -X PUT $C/vehicules/5YJ3E1EA7JF000001 \
       -H "Content-Type: application/json" \
       -d '{"_rev": "1-7c4a...", "marque": "Tesla",
            "annee": 2012, "proprietaire": "Minh"}'
```

> Les requêtes Mango, introduites dans CouchDB 2, offrent une syntaxe déclarative proche de celle de MongoDB. Comme dans MongoDB, il faut créer un index pour que la requête ne parcoure pas toute la base :

```
% curl -X POST $C/vehicules/_index \
       -H "Content-Type: application/json" \
       -d '{"index": {"fields": ["proprietaire"]}}'
% curl -X POST $C/vehicules/_find \
       -H "Content-Type: application/json" \
       -d '{"selector": {"proprietaire": "Minh"},
            "fields": ["_id", "marque", "annee"]}'
```


## 13.9 Étude de cas : un registre des propriétaires de véhicules

> Reprenons l’exemple du chapitre 1 : un registre des propriétaires successifs de véhicules, où chaque transfert de propriété doit être conservé et où toute altération doit être détectable. Nous construisons ce registre au-dessus de LevelDB, dans un répertoire distinct de celui de la section 13.5, don…

```
import hashlib, json, time, plyvel

db = plyvel.DB("/tmp/registre_vehicules", create_if_missing=True)

def empreinte(tx: dict) -> str:
    texte = json.dumps(tx, sort_keys=True).encode()
    return hashlib.sha256(texte).hexdigest()

def dernier():
    for cle, val in db.iterator(prefix=b"tx:", reverse=True):
        return json.loads(val)
    return None

def ajouter(vin: str, proprietaire: str) -> dict:
    prec = dernier()
    tx = {"no": (prec["no"] + 1) if prec else 1,
          "vin": vin, "proprietaire": proprietaire,
          "moment": time.time(),
          "precedent": prec["hash"] if prec else "0" * 64}
    tx["hash"] = empreinte(tx)
    with db.write_batch() as lot:
        lot.put(f"tx:{tx['no']:09d}".encode(),
                json.dumps(tx).encode())
        lot.put(f"vin:{vin}".encode(), json.dumps(tx).encode())
    return tx
```

> La fonction ajouter écrit deux clés dans le même lot atomique : l’entrée du journal (tx:), qui ne sera plus jamais modifiée, et l’état courant du véhicule (vin:), qui donne le propriétaire actuel sans relire tout l’historique. C’est exactement la séparation entre le registre et l’état du monde de Hy…

```
def verifier() -> bool:
    attendu = "0" * 64
    for cle, val in db.iterator(prefix=b"tx:"):
        tx = json.loads(val)
        h = tx.pop("hash")
        if tx["precedent"] != attendu or empreinte(tx) != h:
            print("Altération détectée à la transaction", tx["no"])
            return False
        attendu = h
    return True

ajouter("5YJ3E1EA7JF000001", "Julie Tremblay")
ajouter("5YJ3E1EA7JF000001", "Minh Nguyen")
print(verifier())          # True
```


## Récupérer le code fourni

> Modalités : en équipes d’au moins deux personnes

```
# Cloner le repo avec le code pré-écrit
git clone https://github.com/rodrigueNTprojects/tp_levelDB_IND500.git
cd tp_levelDB_IND500

# Installer dépendances
go mod download
```


## Compiler tous les outils

> Linux/macOS:

```
# Utiliser le Makefile
make build

# Ou manuellement:
go build -o bin/setup ./cmd/setup
go build -o bin/loader ./cmd/loader
go build -o bin/query ./cmd/query
go build -o bin/replicator ./cmd/replicator
go build -o bin/compare ./cmd/compare
```

> Windows:

```
# Compilation manuelle
# Si le dossier n’existe pas il faut le créer
mkdir bin

# Ensuite, exécuter les commandes suivantes
go build -o bin\setup.exe .\cmd\setup
go build -o bin\loader.exe .\cmd\loader
go build -o bin\query.exe .\cmd\query
go build -o bin\replicator.exe .\cmd\replicator
go build -o bin\compare.exe .\cmd\compare
```


## Données de test

> Le dossier data/ contient des fichiers CSV avec des données de test (par exemple un maximum de 18 000 documents):

```
data/
├── orders.csv
├── products.csv
├── sellers.csv
├── leads_qualified.csv
└── ...
```

> Note: Vous pouvez limiter le nombre de documents à charger avec l’option -limit :

```
# Linux/macOS:
./bin/loader -csv ./data -limit 1000

# Windows:
.\bin\loader.exe -csv .\data -limit 1000
```


## Mission 0.1 : comprendre l’architecture de LevelDB (5 points)

> Action:

```
# 1. Initialiser les nœuds

# Linux/macOS:
./bin/setup

# Windows:
.\bin\setup.exe

# 2. Observer la structure créée

# Linux/macOS:
ls -la leveldb-stores/node1/

# Windows (PowerShell):
Get-ChildItem -Force leveldb-stores\node1

# Windows (cmd):
dir /S leveldb-stores\node1

# Exemple de sortie attendue:
# leveldb-stores/node1/
# ├── 000005.ldb          # SSTable (fichier trié)
# ├── 000006.log          # Write-Ahead Log (WAL)
# ├── CURRENT             # Pointeur version actuelle
# ├── LOCK                # Verrou
# └── MANIFEST-000004     # Métadonnées
```


## Mission 0.2 : PUT et GET avec intégrité (5 points)

> Test:

```
# Linux/macOS:
go run missions/mission_0_2.go

# Windows:
go run missions\mission_0_2.go
```


## Mission 0.3 : lot atomique (5 points)

> Test:

```
# Linux/macOS:
go run missions/mission_0_3.go

# Windows:
go run missions\mission_0_3.go
```


## Mission 0.4 : instantané et restauration (10 points)

> Action:

```
# 1. Charger quelques données de test

# Linux/macOS:
./bin/loader -csv ./data -limit 1000

# Windows:
.\bin\loader.exe -csv .\data -limit 1000

# 2. Vérifier le nombre de documents

# Linux/macOS:
./bin/query -count

# Windows:
.\bin\query.exe -count

# 3. Créer un snapshot (copie complète)

# Linux/macOS:
./bin/setup -snapshot node1

# Windows:
.\bin\setup.exe -snapshot node1
```

> Maintenant, simulons un changement de données : Exécuter le script du fichier mission_0_4_modify.go qui a été fourni

```
# Exécuter la modification

# Linux/macOS:
go run missions/mission_0_4_modify.go

# Windows:
go run missions\mission_0_4_modify.go

# Vérifier qu’un document a bien été modifié

# Linux/macOS:
./bin/query -get order:00001

# Windows:
.\bin\query.exe -get order:00001

# Maintenant restaurer depuis le snapshot

# Linux/macOS:
./bin/setup -restore node1,snapshots/node1_XXXXXXXXX

# Windows:
.\bin\setup.exe -restore node1,snapshots\node1_XXXXXXXXX
# (Remplacez XXXXXXXXX par le timestamp dans votre dossier)

# Vérifier que le document est revenu à son état initial

# Linux/macOS:
./bin/query -get order:00001

# Windows:
.\bin\query.exe -get order:00001
```


## Mission 1.1 : indexation secondaire (10 points)

> Test:

```
# Linux/macOS:
go run missions/mission_1_1.go

# Windows:
go run missions\mission_1_1.go
```

> Après avoir créé les index, testez la recherche avec l’outil query:

```
# Linux/macOS:
./bin/query -index region -value NA

# Windows:
.\bin\query.exe -index region -value NA
```


## Mission 1.2 : réplication manuelle (5 points)

> Expérience 1 : Réplication simple

```
# 1. Export node1 → fichier JSON

# Linux/macOS:
./bin/replicator -action export -source node1 -output export.json

# Windows:
.\bin\replicator.exe -action export -source node1 -output export.json

# 2. Import du fichier JSON → node2

# Linux/macOS:
./bin/replicator -action import -target node2 -input export.json

# Windows:
.\bin\replicator.exe -action import -target node2 -input export.json

# 3. Valider la cohérence

# Linux/macOS:
./bin/replicator -action validate -node1 node1 -node2 node2

# Windows:
.\bin\replicator.exe -action validate -node1 node1 -node2 node2
```

> Exécuter le script du fichier test_conflict.go qui a été fourni

```
# Linux/macOS:
go run missions/test_conflict.go
# Puis suivez les instructions à l’écran

# Windows:
go run missions\test_conflict.go
# Puis suivez les instructions à l’écran
```


## Mission 1.3 : compactage manuel (5 points)

> Action:

```
# 1. Nettoyer les nœuds existants

# Linux/macOS:
./bin/setup -clean
./bin/setup
./bin/loader -csv ./data -limit 1000

# Windows:
.\bin\setup.exe -clean
.\bin\setup.exe
.\bin\loader.exe -csv .\data -limit 1000

# 2. Ajouter des données par petits lots pour créer plusieurs fichiers
# Exécuter un des scripts de chargement par lot de 500 fichiers avec offset suivant: scripts/load_batches.sh, scripts/load_batches.ps1, scripts/load_batches.bat

# Linux/macOS:
# Rendre le script exécutable
chmod +x scripts/load_batches.sh
# Exécuter le script
./scripts/load_batches.sh


# Windows (PowerShell):
.\scripts\load_batches.ps1

# Windows (cmd):
.\scripts\load_batches.bat

# 3. Observer les fichiers créés

# Linux/macOS:
ls -lh leveldb-stores/node1/*.ldb

# Windows (PowerShell):
Get-ChildItem leveldb-stores\node1\*.ldb | Format-Table Name,Length

# Windows (cmd):
dir leveldb-stores\node1\*.ldb
```

> Trouvez le fichier missions/compact.go:

```
# Exécuter la compaction

# Linux/macOS:
go run missions/compact.go node1

# Windows:
go run missions\compact.go node1

# Observer les fichiers après compaction

# Linux/macOS:
ls -lh leveldb-stores/node1/*.ldb

# Windows (PowerShell):
Get-ChildItem leveldb-stores\node1\*.ldb | Format-Table Name,Length

# Windows (cmd):
dir leveldb-stores\node1\*.ldb
```


## Mission 1.4 : banc d’essai et analyse (5 points)

> <!-- -->

```
# Exécuter le benchmark

# Linux/macOS:
./bin/compare -dataset 5000

# Windows:
.\bin\compare.exe -dataset 5000
```


## Dataset

> scripts/load_batches.bat - chargement par batch avec offset sur cmd.

```
data/*.csv.
```


## Installation

> Navigateur Web récent.

```
# Cloner le projet
git clone https://github.com/rodrigueNTprojects/couchdb-tp.git
cd couchdb-tp

# Télécharger les dépendances Go
go mod download
```


## Compilation des outils

> Windows (PowerShell/CMD) :

```
go build -o bin\setup.exe .\cmd\setup
go build -o bin\loader.exe .\cmd\loader
go build -o bin\monitor.exe .\cmd\monitor
go build -o bin\cleanup.exe .\cmd\cleanup
```

> Linux/macOS (Terminal) :

```
go build -o bin/setup ./cmd/setup
go build -o bin/loader ./cmd/loader
go build -o bin/monitor ./cmd/monitor
go build -o bin/cleanup ./cmd/cleanup
```

> Alternative avec Makefile (Linux/macOS uniquement) :

```
make build
```


## Démarrage de la grappe Docker

> Tous systèmes :

```
docker compose -f docker/docker-compose-cluster.yml up -d

# Vérifier que les 4 conteneurs sont démarrés
docker ps
```


## 13.11.4 Structure du projet

> Le TP se base sur un modèle e-commerce SQL : customers, geolocation, orders, order_items, order_payments, order_reviews, products, product_category_name_translation, sellers, leads_qualified, leads_closed

```
couchdb-tp/
├── README.md                          # Ce fichier
├── go.mod                             # Dépendances Go
├── Makefile                           # Automatisation (Linux/macOS)
├── docker/
│   └── docker-compose-cluster.yml     # Configuration 4 nœuds
├── data/                              # Fichiers CSV source
├── cmd/                               # Applications exécutables
│   ├── setup/main.go                  # Configuration cluster
│   ├── loader/main.go                 # Chargement données
│   ├── monitor/main.go                # Surveillance
│   ├── cleanup/main.go                # Nettoyage
│   ├── scenario_offline_equipA.go     # Scénario panne équipe A
│   ├── scenario_offline_equipB.go     # Scénario panne équipe B
│   └── conflict-resolver/main.go      # Résolution conflits
├── pkg/                               # Packages réutilisables
│   ├── client/client.go               # Client HTTP CouchDB
│   ├── cluster/cluster.go             # Gestion cluster
│   ├── loader/loader.go               # Logique chargement
│   ├── monitor/monitor.go             # Logique surveillance
│   └── conflict/resolver.go           # Résolution conflits
├── bin/                               # Binaires compilés
└── config.go                          # Configuration cluster (à compléter)
```


## Travail à réaliser

> Exemple de format :

```
{Source: "NA1", Target: "EU1", Name: "na1_to_eu1"},
{Source: "EU1", Target: "NA1", Name: "eu1_to_na1"},
```

> Windows :

```
# Recompiler après modification
go build -o bin\setup.exe .\cmd\setup

# Exécuter la configuration
.\bin\setup.exe -mode setup
```

> Linux/macOS :

```
# Recompiler après modification
go build -o bin/setup ./cmd/setup

# Exécuter la configuration
./bin/setup -mode setup
```

> Tous systèmes :

```
# Vérifier le statut du cluster
./bin/setup -mode verify        # Linux/macOS
.\bin\setup.exe -mode verify    # Windows

# Surveiller une base
./bin/monitor -database ecommerce_orders        # Linux/macOS
.\bin\monitor.exe -database ecommerce_orders    # Windows
```


## Schémas de transformation SQL → NoSQL

> Sources SQL : orders + order_items + order_payments + order_reviews + customers + geolocation

```
{
  "_id": "ledger_transaction_[order_id]",
  "ledger_type": "commercial_transaction",
  "immutable": true,
  "transaction_hash": "sha256_hash",
  "timestamp": "order_purchase_timestamp",
  "audit_trail": {
    "created_by": "csv_loader_system",
    "created_at": "2024-01-15T10:30:00Z",
    "source_node": "NA1",
    "validation_hash": "sha256_hash",
    "integrity_check": "validated",
    "ledger_version": "1.0"
  },
  "transaction_data": {
    "order_id": "...",
    "customer": {
      "customer_id": "...",
      "location": {
        "city": "customer_city",
        "state": "customer_state",
        "coordinates": [lat, lng]
      }
    },
    "order_details": {
      "items": [...],
      "totals": {...}
    },
    "payments": [...],
    "reviews": [...]
  }
}
```

> Sources SQL : products + product_category_name_translation

```
{
  "_id": "ledger_product_[product_id]_v1",
  "ledger_type": "product_definition",
  "version": 1,
  "product_hash": "sha256_hash",
  "audit_trail": {...},
  "product_data": {
    "product_id": "...",
    "category": "product_category_name",
    "category_english": "...",
    "specifications": {
      "dimensions": {
        "weight_g": "...",
        "length_cm": "...",
        "height_cm": "...",
        "width_cm": "..."
      }
    }
  }
}
```

> Sources SQL : sellers + geolocation

```
{
  "_id": "ledger_seller_[seller_id]",
  "ledger_type": "partner_registry",
  "certification_status": "active",
  "seller_hash": "sha256_hash",
  "audit_trail": {...},
  "seller_data": {
    "seller_id": "...",
    "business_info": {
      "city": "seller_city",
      "state": "seller_state"
    },
    "location": {
      "coordinates": [lat, lng],
      "region": "north_america|europe|asia_pacific"
    }
  }
}
```

> Sources SQL : leads_qualified + leads_closed

```
{
  "_id": "ledger_lead_[mql_id]",
  "ledger_type": "sales_pipeline",
  "pipeline_stage": "qualified|closed",
  "lead_hash": "sha256_hash",
  "audit_trail": {...},
  "lead_data": {
    "mql_id": "...",
    "qualification": {...},
    "conversion": {...}
  }
}
```


## Travail à réaliser

> Windows :

```
.\bin\loader.exe -csv .\data -verbose
```

> Linux/macOS :

```
./bin/loader -csv ./data -verbose
```

> Tous systèmes :

```
# Surveiller chaque base
./bin/monitor -database ecommerce_orders     # Linux/macOS
./bin/monitor -database ecommerce_products
./bin/monitor -database ecommerce_sellers
./bin/monitor -database ecommerce_leads

# Windows : remplacer ./bin/monitor par .\bin\monitor.exe
```


## Phase 2A : scénarios hors ligne par équipe (15 points)

> Windows :

```
go build -o bin\scenario-a.exe .\cmd\scenario_offline_equipA.go
go build -o bin\scenario-b.exe .\cmd\scenario_offline_equipB.go
```

> Linux/macOS :

```
go build -o bin/scenario-a ./cmd/scenario_offline_equipA.go
go build -o bin/scenario-b ./cmd/scenario_offline_equipB.go
```

> Équipe A :

```
./bin/scenario-a        # Linux/macOS
.\bin\scenario-a.exe    # Windows
```

> Équipe B :

```
./bin/scenario-b        # Linux/macOS
.\bin\scenario-b.exe    # Windows
```

> Démarche de résolution :

```
Conflit détecté → Récupérer révisions → Comparer timestamps → Garder la plus récente → Supprimer l’ancienne
```

> Windows :

```
go build -o bin\conflict-resolver.exe .\cmd\conflict-resolver
```

> Linux/macOS :

```
go build -o bin/conflict-resolver ./cmd/conflict-resolver
```

> Utilisation :

```
# Lister les conflits
# Linux/macOS
./bin/conflict-resolver -database ecommerce_orders -list
./bin/conflict-resolver -database ecommerce_leads -list
# Windows
.\bin\conflict-resolver.exe -database ecommerce_orders -list
.\bin\conflict-resolver.exe -database ecommerce_leads -list

# Résoudre un conflit
# Linux/macOS
./bin/conflict-resolver -database ecommerce_orders -doc test_order_conflict
./bin/conflict-resolver -database ecommerce_leads -doc lead_sync_conflict
# Windows
.\bin\conflict-resolver.exe -database ecommerce_orders -doc test_order_conflict
.\bin\conflict-resolver.exe -database ecommerce_leads -doc lead_sync_conflict
```


## Équipe A : 5 vues d’intégrité et audit

> Base : ecommerce_orders | Design : _design/audit | Vue : integrity_verification | Reduce : Aucune

```
function(doc) {
  if (doc.ledger_type === 'commercial_transaction' && doc.transaction_hash) {
    emit(doc.audit_trail.source_node, {
      order_id: doc.transaction_data ? doc.transaction_data.order_id : null,
      transaction_hash: doc.transaction_hash,
      integrity_status: doc.audit_trail.integrity_check,
      created_at: doc.audit_trail.created_at
    });
  }
}
```

> Base : ecommerce_orders | Design : _design/audit | Vue : outage_impact_audit | Reduce : Aucune

```
function(doc) {
  if (doc.audit_trail && doc.audit_trail.created_at) {
    var date = new Date(doc.audit_trail.created_at);
    var month = date.getFullYear() + '-' + (date.getMonth() + 1).toString().padStart(2, '0');
    var duringOutage = doc.audit_trail.modification === 'during_na2_outage' ||
                      (doc.transaction_data && doc.transaction_data.modified_during_outage);

    emit([month, doc.ledger_type, duringOutage ? 'during_outage' : 'normal'], {
      id: doc._id,
      source_node: doc.audit_trail.source_node,
      outage_marker: duringOutage
    });
  }
}
```

> Base : ecommerce_orders | Design : _design/audit | Vue : node_sync_performance | Reduce : Aucune

```
function(doc) {
  if (doc.audit_trail && doc._rev) {
    var revisionNumber = parseInt(doc._rev.split('-')[0]);
    emit([doc.audit_trail.source_node, doc.ledger_type], {
      doc_id: doc._id,
      revision_count: revisionNumber,
      has_conflicts: doc._conflicts ? doc._conflicts.length : 0,
      sync_indicator: revisionNumber > 1 ? 'replicated' : 'original'
    });
  }
}
```

> Base : ecommerce_orders | Design : _design/audit | Vue : conflict_detection | Reduce : _count

```
function(doc) {
  if (doc._conflicts) {
    emit(['conflict_detected', doc.ledger_type], {
      doc_id: doc._id,
      conflicts: doc._conflicts,
      audit_source: doc.audit_trail.source_node
    });
  }
  if (doc.audit_trail && doc.audit_trail.validation_hash) {
    emit(['integrity_check', doc.audit_trail.validation_hash], {
      doc_id: doc._id,
      ledger_type: doc.ledger_type
    });
  }
}
```


## Équipe B : 5 vues de traçabilité d’affaires

> Base : ecommerce_leads | Design : _design/sales_audit | Vue : pipeline_resilience | Reduce : Aucune

```
function(doc) {
  if (doc.ledger_type === 'sales_pipeline') {
    var hasConflict = doc._conflicts && doc._conflicts.length > 0;
    var isTestLead = doc.lead_data.mql_id === 'sync_test' || doc._id.includes('lead_sync_conflict');

    emit([doc.pipeline_stage, hasConflict ? 'with_conflict' : 'clean'], {
      lead_id: doc.lead_data.mql_id,
      source_node: doc.audit_trail ? doc.audit_trail.source_node : 'unknown',
      test_scenario: isTestLead
    });
  }
}
```

> Base : ecommerce_leads | Design : _design/sales_audit | Vue : user_action_audit | Reduce : Aucune

```
function(doc) {
  if (doc.audit_trail) {
    emit([doc.audit_trail.created_by, doc.ledger_type], {
      action_timestamp: doc.audit_trail.created_at,
      document_id: doc._id,
      source_node: doc.audit_trail.source_node
    });
  }
}
```

> Base : ecommerce_leads | Design : _design/sales_audit | Vue : post_incident_distribution | Reduce : Aucune

```
function(doc) {
  if (doc.audit_trail && doc.audit_trail.source_node) {
    var nodeRegion = doc.audit_trail.source_node.substring(0, 2);
    var docStatus = doc.audit_trail.conflict_resolved_at ? 'resolved' :
                   (doc._conflicts ? 'conflicted' : 'normal');

    emit([nodeRegion, doc.ledger_type, docStatus], {
      doc_count: 1,
      incident_impact: doc.audit_trail.conflict_resolved_at || doc._conflicts ? 'affected' : 'unaffected'
    });
  }
}
```

> Base : ecommerce_leads | Design : _design/sales_audit | Vue : synchronization_performance | Reduce : CUSTOM

```
// Map function avec pré-calcul
function(doc) {
  if (!doc.audit_trail || !doc._rev) {
    return;
  }

  var revisionNumber = parseInt(doc._rev.split('-')[0]);

  // Émettre seulement les informations essentielles
  if (revisionNumber > 1) {
    emit([doc.audit_trail.source_node, 'R'], 1); // R = Replicated
  } else {
    emit([doc.audit_trail.source_node, 'O'], 1); // O = Original
  }
}

// Reduce optimisé : simple comptage
function(keys, values, rereduce) {
  return sum(values);
}
```


## Tests des vues avec curl

> Tous systèmes (curl disponible nativement) :

```
# Équipe A - Tests
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_orders/_design/audit/_view/integrity_verification"
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_orders/_design/audit/_view/outage_impact_audit"
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_orders/_design/audit/_view/geographic_distribution"
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_orders/_design/audit/_view/node_sync_performance"
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_orders/_design/audit/_view/conflict_detection?group=true"

# Équipe B - Tests
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_leads/_design/sales_audit/_view/pipeline_resilience"
curl "http://admin:ecommerce2024@localhost:5989/ecommerce_sellers/_design/sales_audit/_view/partner_certification"
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_leads/_design/sales_audit/_view/user_action_audit"
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_leads/_design/sales_audit/_view/post_incident_distribution"
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_leads/_design/sales_audit/_view/synchronization_performance?reduce=true&group=true"
```


## Analyse des performances

> Équipe B :

```
curl -w "\nTemps NA1: %{time_total}s\n" "http://admin:ecommerce2024@localhost:5987/ecommerce_leads/_design/sales_audit/_view/synchronization_performance?reduce=true&group=true"
curl "http://admin:ecommerce2024@localhost:5987/ecommerce_leads" | grep -o '"doc_count":[0-9]*'   # Windows : | findstr doc_count
```


## Tests de performance comparative

> Équipe B :

```
curl -w "\nTemps NA1: %{time_total}s\n" "http://admin:ecommerce2024@localhost:5987/ecommerce_leads/_design/sales_audit/_view/synchronization_performance_optimized?reduce=true&group=true"
```

> # Vue optimisée sur NA2

```
curl -w "\nTemps NA2: %{time_total}s\n" "http://admin:ecommerce2024@localhost:5988/ecommerce_leads/_design/sales_audit/_view/synchronization_performance_optimized?reduce=true&group=true"
```

> # Vue optimisée sur EU1

```
curl -w "\nTemps EU1: %{time_total}s\n" "http://admin:ecommerce2024@localhost:5989/ecommerce_leads/_design/sales_audit/_view/synchronization_performance_optimized?reduce=true&group=true"
```

> # Vue optimisée sur AP1

```
curl -w "\nTemps AP1: %{time_total}s\n" "http://admin:ecommerce2024@localhost:5990/ecommerce_leads/_design/sales_audit/_view/synchronization_performance_optimized?reduce=true&group=true"
```
