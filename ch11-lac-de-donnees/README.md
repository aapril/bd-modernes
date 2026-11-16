# Chapitre 11 : Les lacs de données (MinIO, DuckDB)

## 1. Prérequis

- Docker Desktop, démarré,
- Python 3.12 ou plus récent,
- le serveur PostgreSQL du chapitre 2, pour l’étude de cas de la section 11.7,
- facultativement, un compte AWS pour Amazon Athena (section 11.5.1) ; les autres exemples n’en ont pas besoin.

Le dépôt utilise l’image cgr.dev/chainguard/minio, qui contient le serveur et le client mc, ainsi que DuckDB et boto3.

## 2. Installer

MinIO, présenté à la section 11.1, offre une API compatible avec S3 et s’exécute sur un poste de travail. L’image de Chainguard (cgr.dev/chainguard/minio) contient à la fois le serveur et le client mc (Chainguard s.d.). Le fichier compose.yaml du dossier ch11-lac-de-donnees démarre le serveur, nommé minio, sur les ports 9000 (API S3) et 9001 (console Web), et rend les fichiers de données du chapitre 3 visibles dans le conteneur sous /donnees :
```
cd bd-modernes/ch11-lac-de-donnees
docker compose up -d
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```
Sans le dépôt, la commande suivante démarre le même serveur :
```
docker run -d --name minio -p 9000:9000 -p 9001:9001 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    cgr.dev/chainguard/minio server /data --console-address ":9001"
```

## 3. Autres méthodes d’installation

- **Garage** et **SeaweedFS** sont deux autres serveurs libres compatibles avec S3 qui conviennent aussi aux exercices,
- **Amazon S3** : le même code fonctionne en retirant le paramètre endpoint_url et en utilisant vos clés d’accès AWS.

## 4. Vérifier l’installation

La commande suivante interroge le point de santé de MinIO ; elle doit retourner le code 200 :
```
curl -s -o /dev/null -w "%{http_code}\n" \
       http://localhost:9000/minio/health/live
```
Résultat attendu :
```
200
```
La console Web est accessible à l’adresse http://localhost:9001, avec l’utilisateur minioadmin et le mot de passe minioadmin.

## 5. Charger les données

Les fichiers vins.csv et Films.json viennent du chapitre 3. Les réservations du Club Sportif sont lues dans la base club : le programme exporter_reservations.py du dossier les écrit, une journée par fichier, dans la zone bronze (CSV) et dans la zone argent (Parquet) du compartiment lac-club, comme le ferait le pipeline Dagster du chapitre 10 :
```
python exporter_reservations.py
```

## 6. En cas de problème

- **boto3 répond « Could not connect to the endpoint URL »** : le conteneur minio n’est pas démarré, ou l’adresse n’est pas http://localhost:9000,
- **DuckDB ne trouve aucun fichier** : vérifiez le compartiment et le préfixe avec `docker exec minio mc ls --recursive local/lac-club`,
- **le port 9000 est occupé**, souvent par un autre outil de développement : changez le port de gauche dans compose.yaml et dans endpoint_url.

## 7. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
docker compose down -v
```
