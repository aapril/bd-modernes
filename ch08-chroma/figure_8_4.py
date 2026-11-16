import requests
import chromadb
from chromadb.utils import embedding_functions
if __name__ == '__main__':
    # Création d’un dossier pour la persistance des données
    chroma_client = chromadb.PersistentClient(path="vectordb")
    # Initialisation de la fonction de plongement
    plongement = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="Qwen/Qwen3-Embedding-0.6B", normalize_embeddings=True)
    # Création de la collection, ou récupération si elle existe déjà
    collection = chroma_client.get_or_create_collection(name="donnees_quebec", embedding_function=plongement)
    # API de Données Québec : les jeux de données sont lus par pages de 1000
    url = 'https://www.donneesquebec.ca/recherche/api/3/action/package_search'
    jeuxDeDonnees = []
    while True:
        reponse = requests.get(url, params={'rows': 1000, 'start': len(jeuxDeDonnees)}, timeout=60)
        page = reponse.json()['result']['results']
        if not page:
            break
        jeuxDeDonnees.extend(page)
    # Description (notes), titre et identifiant de chaque jeu de données
    ids = [jeu['id'] for jeu in jeuxDeDonnees]
    notes = [jeu.get('notes') or "" for jeu in jeuxDeDonnees]
    titres = [{"titre": jeu.get('title') or ""} for jeu in jeuxDeDonnees]
    # Ajout à la collection, par lots de 100 jeux de données
    for i in range(0, len(ids), 100):
        collection.add(ids=ids[i:i+100], documents=notes[i:i+100], metadatas=titres[i:i+100])
    print(collection.count())
