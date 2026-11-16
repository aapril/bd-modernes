# Chapitre 9 : Les bases de données orientées colonnes (HBase)

## 1. Prérequis

- un JDK 17 (ou 11),
- macOS ou Linux ; sous Windows, une distribution Ubuntu sous WSL 2, dans laquelle toutes les commandes du chapitre s’exécutent telles quelles,
- curl et tar, présents par défaut sur ces systèmes.

Les commandes et les résultats du chapitre ont été vérifiés avec HBase 2.6.7 en mode autonome, sur macOS.

## 2. Installer

Pour les exercices, HBase est exécuté en mode autonome (standalone) : un seul processus Java contient le HMaster, un serveur de régions et ZooKeeper, et les données sont écrites sur le disque local plutôt que dans HDFS. Le projet HBase ne publie pas d’image Docker officielle ; on installe donc la distribution binaire. Installez d’abord le JDK 17 :
```
brew install openjdk@17              # macOS
sudo apt install openjdk-17-jdk      # Ubuntu ou WSL 2
```
Les commandes de la suite sont présentées sans l’invite du terminal (%) ni celle du shell HBase (hbase:001:0>), pour que vous puissiez les copier-coller directement. Téléchargez et décompressez la distribution :
```
curl -O https://dlcdn.apache.org/hbase/2.6.7/hbase-2.6.7-bin.tar.gz
tar xzf hbase-2.6.7-bin.tar.gz
cd hbase-2.6.7
```

## 3. Autres méthodes d’installation

- le site de téléchargement ne conserve que les dernières versions : si une version plus récente de la série 2.6 figure sur hbase.apache.org/downloads, remplacez le numéro dans les trois commandes,
- Java doit être indiqué à HBase : sous macOS, `export JAVA_HOME=$(/usr/libexec/java_home -v 17)` ; sous Ubuntu ou WSL 2, `export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`,
- la page de téléchargement présente aussi la série 2.5, désignée comme version stable, et la série 3.0, nouvelle version majeure publiée en août 2026.

Démarrez ensuite HBase et ouvrez son shell :

## 4. Vérifier l’installation

Dans le shell, la commande status confirme que le serveur fonctionne :
```
bin/start-hbase.sh
bin/hbase shell
status
```
Résultat attendu :
```
1 active master, 0 backup masters, 1 servers, 0 dead, 2.0000 average load
```
La charge moyenne (average load) varie. L’interface Web du HMaster est disponible à l’adresse http://localhost:16010 ; elle montre les tables, les régions et leur répartition.

## 5. Charger les données

Les tables du chapitre sont créées par les commandes des sections 9.4 à 9.6. Le script verifier_chapitre9.sh du dépôt les exécute toutes et compare chaque résultat à celui du livre ; copiez-le dans le dossier de HBase, puis lancez-le :
```
cp ../bd-modernes/ch09-hbase/verifier_chapitre9.sh .
bash verifier_chapitre9.sh > resultats_chapitre9.txt
```

## 6. En cas de problème

- **« JAVA_HOME is not set »** : exportez JAVA_HOME dans le terminal où vous lancez HBase,
- **le shell affiche « Server is not running yet »** : le démarrage prend une trentaine de secondes ; patientez, puis réessayez,
- **le port 16010 ou 2181 est occupé** : un autre HBase ou ZooKeeper s’exécute déjà ; arrêtez-le avec bin/stop-hbase.sh.

## 7. Arrêter et nettoyer

Lorsque vous aurez terminé les exemples du chapitre :
```
bin/stop-hbase.sh
rm -rf /tmp/hbase-$USER    # supprime les données
```
