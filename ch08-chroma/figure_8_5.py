import chromadb
from sentence_transformers import SentenceTransformer
if __name__ == '__main__':
    # Requête à effectuer sur la base de données
    requete = "Immigration au Québec"
    # Initialiser le client à partir d’un dossier local persistant
    chroma_client = chromadb.PersistentClient(path="vectordb")
    # Obtenir la collection désirée
    collection = chroma_client.get_collection("donnees_quebec")
    # Vectoriser la requête avec l’instruction recommandée par Qwen
    modele = SentenceTransformer("Qwen/Qwen3-Embedding-0.6B")
    vecteur = modele.encode([requete], prompt_name="query", normalize_embeddings=True)
    # Effectuer la requête à la base de données avec trois résultats
    results = collection.query(
        query_embeddings=vecteur,
        n_results=3
    )
    print(results)
