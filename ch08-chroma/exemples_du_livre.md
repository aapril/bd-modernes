# Chapitre 8 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 8.3 Installer Chroma et créer un client

> Chroma s’exécute ici dans le programme Python, sans serveur. Le dossier ch08-chroma du dépôt contient le fichier requirements.txt ; créez un environnement virtuel et installez-y les bibliothèques :

```
% cd bd-modernes/ch08-chroma
% python3 -m venv .venv && source .venv/bin/activate
% pip install -r requirements.txt
```

> Sous Windows, activez l’environnement avec .venv\Scripts\activate. Sans le dépôt, la commande suivante suffit :

```
% pip install chromadb sentence-transformers
```

> La commande suivante affiche la version de Chroma :

```
% python -c "import chromadb; print(chromadb.__version__)"
```

> Le résultat attendu est le suivant :

```
1.5.9
```

> Les données de la section 8.4 sont créées par le code du chapitre. L’étude de cas de la section 8.5 interroge l’API de Données Québec ; les programmes des figures 8.4 et 8.5 sont dans le dossier du dépôt :

```
% python figure_8_4.py
% python figure_8_5.py
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% deactivate
% rm -rf .venv vectordb
```

> Il suffit ensuite d’importer le module dans le programme Python :

```
import chromadb
```

> Pour initialiser un client Chroma sans persistance, on peut utiliser la commande suivante :

```
client = chromadb.Client()
```

> Pour initialiser un client qui persiste les données, on précise dans l’argument path le chemin du dossier qui les contiendra :

```
    client = chromadb.PersistentClient(path='chemin/vers/dossier/persistant')
```


## 8.4.1 Choisir une fonction de plongement

> Pour choisir une autre fonction de plongement, il faut importer le module utilitaire correspondant :

```
    from chromadb.utils import embedding_functions
```

> On précise ensuite le modèle dans l’argument model_name. La classe SentenceTransformerEmbeddingFunction exige d’abord l’installation de la bibliothèque sentence-transformers :

```
pip install sentence-transformers
```

> L’exemple ci-dessous utilise le même modèle que celui par défaut, mais l’exécute avec cette bibliothèque :

```
emb_fn = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")
```


## 8.4.2 Créer une collection

> Pour créer une collection, il suffit de lui donner un nom et, au besoin, une fonction de plongement :

```
collection = client.create_collection(name="nom", embedding_function=emb_fn)
```

> Pour récupérer une collection si elle existe, ou la créer dans le cas contraire, on peut utiliser la commande suivante :

```
collection = client.get_or_create_collection(name='nom', embedding_function=emb_fn)
```

> On peut également choisir la fonction de distance de l’espace vectoriel, au moment de la création seulement, grâce à l’argument configuration :

```
collection_c = client.create_collection(
    name="collection_cosinus",
    configuration={"hnsw": {"space": "cosine"}}
)
```


## 8.4.3 Ajouter des données

> Pour ajouter des données à la collection, on utilise la fonction add :

```
collection.add(
    ids=["id1", "id2"],
    documents=["Le club ouvre une ligue de badminton.",
               "Le cours de yoga du samedi est complet."],
    metadatas=[{"Titre": "Ex1", "Date": "2021"},
               {"Titre": "Ex2", "Date": "2024"}]
)
```


## 8.4.4 Récupérer et modifier des données

> Pour récupérer une collection existante, on utilise get_collection ; l’argument embedding_function est facultatif, puisque Chroma a conservé la configuration de la collection :

```
collection = client.get_collection(name='nom', embedding_function=emb_fn)
```

> Pour récupérer certains éléments d’une collection, on peut utiliser :

```
collection.get(
    ids=["id1", "id2"],
    where={"Date": "2024"}
)
```

> La fonction update met à jour des éléments existants. Si un identifiant n’existe pas dans la collection, Chroma consigne une erreur dans son journal et ignore cet élément, sans lever d’exception.

```
collection.update(
    ids=["id2"],
    documents=["Le cours de yoga du samedi a deux places libres."],
    metadatas=[{"Titre": "Ex2", "Date": "2025"}]
)
```

> La fonction upsert met à jour les éléments qui existent et crée ceux qui n’existent pas :

```
collection.upsert(
    ids=["id2", "id3"],
    documents=["Le cours de yoga du samedi est annulé.",
               "Le tournoi de tennis aura lieu en juin."],
    metadatas=[{"Titre": "Ex2", "Date": "2025"},
               {"Titre": "Ex3", "Date": "2025"}]
)
```


## 8.4.5 Supprimer des données

> Il est possible de supprimer des éléments de la collection à l’aide de leurs identifiants, d’une clause where sur les métadonnées, ou des deux. Comme pour get, lorsque ids et where sont tous deux présents, seuls les éléments qui satisfont aux deux conditions sont supprimés ; ici, seul id3 est suppri…

```
collection.delete(
    ids=["id1", "id3"],
    where={"Date": "2025"}
)
```

> Pour supprimer une collection complètement, on peut utiliser la commande suivante :

```
client.delete_collection(name="collection_cosinus")

```


## 8.4.6 Effectuer une requête de similarité

> La fonction query, elle, retourne les éléments les plus semblables à une requête. Le texte de la requête est vectorisé avec la même fonction de plongement que celle qui a servi à vectoriser les éléments de la collection, puis Chroma retourne les éléments dont les vecteurs sont les plus proches.

```
resultats = collection.query(
    query_texts=["activités de raquette"],
    n_results=2
)
```

> Il est également possible d’ajouter les arguments facultatifs where et where_document. Le premier filtre les éléments selon leurs métadonnées, le second selon le contenu des documents ; on pourrait, par exemple, ne garder que les documents qui contiennent une chaîne de caractères précise. Les deux f…

```
collection.query(
    query_texts=["activités de raquette"],
    n_results=2,
    where={"Date": "2025"},
    where_document={"$contains": "yoga"}
)
```


## 8.5.1 Création de la BD vectorielle

> Il est à noter que pour obtenir des résultats plus concluants, il serait nécessaire de conserver plus de champs. En effet, l’API de Données Québec donne beaucoup d’autres informations pertinentes, qui permettraient d’affiner les résultats des requêtes. Pour cet exemple cependant, afin de simplifier,…

```
1    import requests
2    import chromadb
3    from chromadb.utils import embedding_functions
4    if __name__ == '__main__':
5        # Création d’un dossier pour la persistance des données
6        chroma_client = chromadb.PersistentClient(path="vectordb")
7        # Initialisation de la fonction de plongement
8        plongement = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="Qwen/Qwen3-Embedding-0.6B", normalize_embeddings=True)
9        # Création de la collection, ou récupération si elle existe déjà
10        collection = chroma_client.get_or_create_collection(name="donnees_quebec", embedding_function=plongement)
11        # API de Données Québec : les jeux de données sont lus par pages de 1000
12        url = 'https://www.donneesquebec.ca/recherche/api/3/action/package_search'
13        jeuxDeDonnees = []
14        while True:
15            reponse = requests.get(url, params={'rows': 1000, 'start': len(jeuxDeDonnees)}, timeout=60)
16            page = reponse.json()['result']['results']
17            if not page:
18                break
19            jeuxDeDonnees.extend(page)
20        # Description (notes), titre et identifiant de chaque jeu de données
21        ids = [jeu['id'] for jeu in jeuxDeDonnees]
22        notes = [jeu.get('notes') or "" for jeu in jeuxDeDonnees]
23        titres = [{"titre": jeu.get('title') or ""} for jeu in jeuxDeDonnees]
24        # Ajout à la collection, par lots de 100 jeux de données
25        for i in range(0, len(ids), 100):
26            collection.add(ids=ids[i:i+100], documents=notes[i:i+100], metadatas=titres[i:i+100])
27        print(collection.count())
```


## 8.5.2 Requête sur la base de données

> Pour effectuer la requête, on utilise ensuite la fonction collection.query. L’argument query_embeddings reçoit le vecteur de la requête ; il remplace l’argument query_texts, qui recevrait plutôt le texte de la requête et le ferait vectoriser, sans instruction, par la fonction de plongement de la col…

```
1    import chromadb
2    from sentence_transformers import SentenceTransformer
3    if __name__ == '__main__':
4        # Requête à effectuer sur la base de données
5        requete = "Immigration au Québec"
6        # Initialiser le client à partir d’un dossier local persistant
7        chroma_client = chromadb.PersistentClient(path="vectordb")
8        # Obtenir la collection désirée
9        collection = chroma_client.get_collection("donnees_quebec")
10        # Vectoriser la requête avec l’instruction recommandée par Qwen
11        modele = SentenceTransformer("Qwen/Qwen3-Embedding-0.6B")
12        vecteur = modele.encode([requete], prompt_name="query", normalize_embeddings=True)
13        # Effectuer la requête à la base de données avec trois résultats
14        results = collection.query(
15            query_embeddings=vecteur,
16            n_results=3
17        )
18        print(results)
```

> Tableau 8.1 – Résultat de la requête « Immigration au Québec »

```
{'ids': [['12b932d4-2c84-443f-8d5e-a267b02e26b1',
   'dd2328a3-6033-4389-acdd-48ff87580a76',
   '8ff5901b-84a7-47a3-bfc0-1cea9219f952']],
 'embeddings': None,
 'documents': [["Des données relatives aux taux de présence des personnes immigrantes admises au Québec dans la dernière décennie selon certaines caractéristiques, dont la durée de résidence, la catégorie d'immigration, la connaissance du français et la scolarité déclarée à l'admission.",
   "Le jeu de données présente des tableaux qui décrivent le volume planifié des admissions des personnes immigrantes au Québec selon la planification pluriannuelle 2024 et 2025 et le plan annuel d'immigration du Québec pour l'année 2024. ",
   "Le jeu de données présente une série de tableaux qui décrivent diverses caractéristiques des personnes immigrantes admises au Québec au cours d'un trimestre."]],
 'uris': None,
 'included': ['metadatas', 'documents', 'distances'],
 'data': None,
 'metadatas': [[{'titre': 'Présence des personnes immigrantes'},
   {'titre': 'Planification des admissions des personnes immigrantes au Québec pour les années 2024 et 2025'},
   {'titre': 'Admission de personnes immigrantes au Québec (trimestriel)'}]],
 'distances': [[0.27828919887542725, 0.3186298608779907, 0.31991881132125854]]}
```

> Tableau 8.2 – Résultat de la requête « caserne de pompier »

```
'documents': [["Ensemble des casernes de pompier du Québec.\r\n\r\nBut: Identifier les casernes de pompiers réparties sur l'ensemble du territoire du Québec.\r\n\r\nAVERTISSEMENT : Ces données peuvent différer de la réalité à certains endroits.",
   "Cet ensemble de données comprend les coordonnées des casernes de pompier du service incendie de la Ville de Montréal.  \r\nL'ensemble de données [Territoires administratifs des casernes](/ville-de-montreal/territoires-administratifs-des-casernes) fournit le territoire couvert par les casernes.",
   "Cartographie des casernes de pompier de l'agglomération Longueuil."]],
 'metadatas': [[{'titre': 'Casernes de pompiers'},
   {'titre': 'Casernes de pompiers sur l’île de Montréal'},
   {'titre': 'Casernes d’incendie'}]],
 'distances': [[0.45379549264907837, 0.4576597809791565, 0.4774630069732666]]
```
