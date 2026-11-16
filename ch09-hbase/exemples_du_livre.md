# Chapitre 9 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 9.1.1 Tables, lignes et familles de colonnes

> Le croisement d’une ligne, d’une famille et d’un qualificatif s’appelle une cellule. Chaque cellule peut conserver plusieurs versions de sa valeur, distinguées par un horodatage. L’adresse complète d’une valeur est donc :

```
(clé de ligne, famille:qualificatif, horodatage) -> valeur
```


## 9.2.3 Tables hautes ou tables larges

> La différence se voit bien dans le shell HBase (section 9.4), que vous pourrez essayer après l’installation de la section 9.3. Dans une table large, chaque passage devient une colonne de la ligne du membre, dont le qualificatif est l’horodatage inversé :

```
create 'passages_large', 'p'
put 'passages_large', 'membre#0027', 'p:9223370305315675807', 'T07'
put 'passages_large', 'membre#0027', 'p:9223370305404175807', 'T03'
get 'passages_large', 'membre#0027'
```


## 9.3 Installer HBase

> Pour les exercices, HBase est exécuté en mode autonome (standalone) : un seul processus Java contient le HMaster, un serveur de régions et ZooKeeper, et les données sont écrites sur le disque local plutôt que dans HDFS. Le projet HBase ne publie pas d’image Docker officielle ; on installe donc la di…

```
% brew install openjdk@17              # macOS
% sudo apt install openjdk-17-jdk      # Ubuntu ou WSL 2
```

> Les commandes de la suite sont présentées sans l’invite du terminal (%) ni celle du shell HBase (hbase:001:0>), pour que vous puissiez les copier-coller directement. Téléchargez et décompressez la distribution :

```
curl -O https://dlcdn.apache.org/hbase/2.6.7/hbase-2.6.7-bin.tar.gz
tar xzf hbase-2.6.7-bin.tar.gz
cd hbase-2.6.7
```

> Dans le shell, la commande status confirme que le serveur fonctionne :

```
bin/start-hbase.sh
bin/hbase shell
status
```

> Le résultat attendu est le suivant :

```
1 active master, 0 backup masters, 1 servers, 0 dead, 2.0000 average load
```

> Les tables du chapitre sont créées par les commandes des sections 9.4 à 9.6. Le script verifier_chapitre9.sh du dépôt les exécute toutes et compare chaque résultat à celui du livre ; copiez-le dans le dossier de HBase, puis lancez-le :

```
cp ../bd-modernes/ch09-hbase/verifier_chapitre9.sh .
bash verifier_chapitre9.sh > resultats_chapitre9.txt
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
bin/stop-hbase.sh
rm -rf /tmp/hbase-$USER    # supprime les données
```


## 9.4.1 Créer et décrire une table

> La commande create reçoit le nom de la table et la description de chaque famille. Ici, la famille info conserve une seule version, alors que activite en conserve trois et expire ses données après un an (TTL en secondes) :

```
create 'membres',
       {NAME => 'info', VERSIONS => 1},
       {NAME => 'activite', VERSIONS => 3, TTL => 31536000}
describe 'membres'
list
```


## 9.4.2 Écrire et lire

> La commande put écrit une cellule. La commande get lit une ligne complète, une famille ou une seule colonne :

```
put 'membres', 'membre#0027', 'info:nom',        'Tremblay'
put 'membres', 'membre#0027', 'info:prenom',     'Julie'
put 'membres', 'membre#0027', 'activite:tennis', '14'
put 'membres', 'membre#0027', 'activite:tennis', '15'
put 'membres', 'membre#0027', 'activite:tennis', '16'
put 'membres', 'membre#0044', 'info:nom',        'Nguyen'

get 'membres', 'membre#0027'
get 'membres', 'membre#0027', 'info'
get 'membres', 'membre#0027', {COLUMN => 'activite:tennis',
                               VERSIONS => 3}
```

> La dernière commande retourne les trois versions conservées de la cellule activite:tennis, soit 16, 15 et 14, de la plus récente à la plus ancienne, chacune avec son horodatage. Les deux commandes put supplémentaires servent justement à créer ces versions. Pour incrémenter un compteur de façon atomi…

```
incr 'membres', 'membre#0027', 'activite:squash', 1
get_counter 'membres', 'membre#0027', 'activite:squash'
```


## 9.4.3 Parcourir des plages de lignes

> La commande scan parcourt les lignes dans l’ordre des clés. On la limite presque toujours à une plage, avec STARTROW (inclusif) et STOPROW (exclusif), ou à un préfixe :

```
scan 'membres', {STARTROW => 'membre#0020',
                 STOPROW  => 'membre#0050'}
scan 'membres', {ROWPREFIXFILTER => 'membre#00',
                 COLUMNS => ['info:nom'], LIMIT => 10}
```

> Des filtres permettent de sélectionner des lignes selon leur contenu. Mais attention : un filtre n’est pas un index. HBase doit quand même lire toutes les lignes de la plage parcourue ; le filtre réduit seulement la quantité de données retournées au client.

```
scan 'membres', {FILTER =>
  "SingleColumnValueFilter('info','nom',=,'binary:Tremblay')"}
```


## 9.4.4 Le modèle de données en action

> Quelques commandes suffisent pour vérifier les propriétés du modèle vues à la section 9.1. D’abord, un qualificatif n’a pas besoin d’être déclaré, mais une famille, oui :

```
put 'membres', 'membre#0027', 'activite:escalade', '2'
put 'membres', 'membre#0027', 'sante:allergies', 'aucune'
```

> La première commande ajoute la colonne activite:escalade sans aucune modification du schéma. La seconde échoue avec l’erreur NoSuchColumnFamilyException, car la famille sante n’a pas été déclarée à la création de la table ; il faudrait d’abord l’ajouter avec alter. Ensuite, une famille ne conserve q…

```
put 'membres', 'membre#0027', 'activite:tennis', '17'
get 'membres', 'membre#0027', {COLUMN => 'activite:tennis', VERSIONS => 5}
```

> Même si la commande demande cinq versions, HBase n’en retourne que trois (17, 16 et 15) : la famille activite a été créée avec VERSIONS => 3, et la valeur 14 n’est plus visible. Enfin, les clés de ligne sont triées octet par octet :

```
put 'membres', 'membre#100', 'info:nom', 'Roy'
put 'membres', 'membre#27', 'info:nom', 'Lavoie'
scan 'membres', {COLUMNS => ['info:nom']}
```

> Le scan retourne membre#0027, membre#0044, membre#100, puis membre#27 : comme le caractère 1 précède le caractère 2, « membre#100 » est rangé avant « membre#27 ». C’est pourquoi les numéros doivent être complétés par des zéros (section 9.2.2). Supprimez ces deux lignes de test :

```
deleteall 'membres', 'membre#100'
deleteall 'membres', 'membre#27'
```


## 9.4.5 Observer le fonctionnement interne

> Le mode autonome permet aussi d’observer l’architecture décrite à la section 9.1. La commande describe affiche, pour chaque famille, les réglages utilisés par le chemin de lecture : BLOOMFILTER => 'ROW' indique un filtre de Bloom sur la clé de ligne, et BLOCKCACHE => 'true' l’utilisation du cache de…

```
describe 'membres'
scan 'hbase:meta', {ROWPREFIXFILTER => 'membres', COLUMNS => ['info:server']}
list_regions 'membres'
```

> Pour suivre le chemin d’écriture, forcez l’écriture du MemStore sur le disque avec flush, modifiez une valeur, puis recommencez :

```
flush 'membres'
put 'membres', 'membre#0027', 'info:nom', 'Tremblay-Roy'
flush 'membres'
```

> Dans un autre terminal, placé dans le dossier de HBase, listez les fichiers de la famille info. Vous y trouvez deux HFile, un par flush. Aucun fichier n’a été modifié : la nouvelle valeur Tremblay-Roy se trouve dans le second.

```
ls tmp/hbase/data/default/membres/*/info/
```

> De retour dans le shell HBase, lancez un compactage majeur :

```
major_compact 'membres'
```

> Quelques secondes plus tard, un nouveau HFile fusionné apparaît dans le dossier ; les anciens sont déplacés vers un dossier d’archive après quelques minutes. Dans le second terminal, l’outil hfile affiche le contenu du fichier le plus récent :

```
F=$(ls -t tmp/hbase/data/default/membres/*/info/* | head -1)
bin/hbase hfile -p -f "file://$PWD/$F"
```

> Le fichier compacté ne contient plus que trois cellules : Tremblay-Roy, Julie et Nguyen. L’ancienne valeur Tremblay, puisque la famille info ne garde qu’une version, et les marqueurs de suppression des lignes membre#100 et membre#27 ont été éliminés. Si vous affichez plutôt l’un des HFile antérieurs…

```
bin/hbase zkcli ls /hbase
```


## 9.4.6 Supprimer et modifier le schéma

> Les commandes suivantes suppriment une cellule, puis une ligne entière, ajoutent une famille à la table, comptent ses lignes et, enfin, suppriment la table :

```
delete    'membres', 'membre#0027', 'activite:tennis'
deleteall 'membres', 'membre#0044'
alter     'membres', {NAME => 'preferences'}   # ajoute une famille
count     'membres'
disable   'membres'
drop      'membres'
```


## 9.5 Accéder à HBase à partir d’un programme

> Le programme suivant est complet. Enregistrez-le dans un fichier Membres.java, dans le dossier de HBase, après avoir recréé la table membres (section 9.4.6) :

```
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.CompareOperator;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.filter.SingleColumnValueFilter;
import org.apache.hadoop.hbase.util.Bytes;

public class Membres {
  public static void main(String[] args) throws Exception {
    Configuration conf = HBaseConfiguration.create();
    try (Connection cn = ConnectionFactory.createConnection(conf);
         Table t = cn.getTable(TableName.valueOf("membres"))) {

      // Create : écrire une cellule
      Put p = new Put(Bytes.toBytes("membre#0058"));
      p.addColumn(Bytes.toBytes("info"), Bytes.toBytes("nom"),
                  Bytes.toBytes("Gagnon"));
      t.put(p);

      // Read : lire une ligne par sa clé
      Result r = t.get(new Get(Bytes.toBytes("membre#0058")));
      String nom = Bytes.toString(
          r.getValue(Bytes.toBytes("info"), Bytes.toBytes("nom")));
      System.out.println("Nom lu : " + nom);

      // Scan : parcourir une plage de clés
      Scan s = new Scan()
          .withStartRow(Bytes.toBytes("membre#0020"))
          .withStopRow(Bytes.toBytes("membre#0060"))
          .addFamily(Bytes.toBytes("info"));
      try (ResultScanner rs = t.getScanner(s)) {
        for (Result ligne : rs) {
          System.out.println(Bytes.toString(ligne.getRow()));
        }
      }

      // Scan avec filtre : les lignes dont info:nom vaut Gagnon
      SingleColumnValueFilter f = new SingleColumnValueFilter(
          Bytes.toBytes("info"), Bytes.toBytes("nom"),
          CompareOperator.EQUAL, Bytes.toBytes("Gagnon"));
      f.setFilterIfMissing(true);
      try (ResultScanner rs = t.getScanner(new Scan().setFilter(f))) {
        for (Result ligne : rs) {
          System.out.println("Filtre : " + Bytes.toString(ligne.getRow()));
        }
      }

      // Delete : supprimer la ligne, puis vérifier qu'elle a disparu
      t.delete(new Delete(Bytes.toBytes("membre#0058")));
      boolean vide = t.get(new Get(Bytes.toBytes("membre#0058"))).isEmpty();
      System.out.println("Get vide : " + vide);
    }
  }
}
```

> La commande bin/hbase classpath fournit la liste des bibliothèques de HBase nécessaires pour compiler et exécuter le programme :

```
javac -cp "$(bin/hbase classpath)" Membres.java
java -cp "$(bin/hbase classpath):." Membres
```


## 9.6 Étude de cas : les passages aux tourniquets du Club Sportif

> En mode autonome, la compression Snappy demande une étape de configuration. La distribution de HBase fournit un codec Snappy fondé sur la bibliothèque snappy-java, qui contient ses propres bibliothèques natives, mais ne l’utilise pas par défaut : sans cette étape, la commande create échoue avec l’er…

```
<property>
  <name>hbase.io.compress.snappy.codec</name>
  <value>org.apache.hadoop.hbase.io.compress.xerial.SnappyCodec</value>
</property>
```

> Créez ensuite la table :

```
create 'passages_par_membre', {NAME => 'p', VERSIONS => 1,
         COMPRESSION => 'SNAPPY', TTL => 94608000},
       {SPLITS => ['01','02','03','04','05','06','07','08',
                   '09','10','11','12','13','14','15']}
```

> Le shell HBase étant un interpréteur Ruby, vous pouvez y calculer la clé vous-même. L’heure de 18 h 05 (heure de l’Est) correspond à 23 h 05 en temps universel :

```
sel = '%02d' % (27 % 16)
inv = java.lang.Long::MAX_VALUE - Time.utc(2024, 11, 13, 23, 5).to_i * 1000
puts "#{sel}#0000027##{inv}"
```

> Pour voir ce fonctionnement, enregistrez deux passages du membre 27, le 13 novembre à 18 h 05 et le 12 novembre à 17 h 30, puis exécutez la requête R1 :

```
put 'passages_par_membre', '11#0000027#9223370305315675807', 'p:tourniquet', 'T07'
put 'passages_par_membre', '11#0000027#9223370305315675807', 'p:site', 'Centre-ville'
put 'passages_par_membre', '11#0000027#9223370305315675807', 'p:sens', 'entree'
put 'passages_par_membre', '11#0000027#9223370305404175807', 'p:tourniquet', 'T03'
put 'passages_par_membre', '11#0000027#9223370305404175807', 'p:site', 'Rosemont'
put 'passages_par_membre', '11#0000027#9223370305404175807', 'p:sens', 'sortie'
scan 'passages_par_membre', {ROWPREFIXFILTER => '11#0000027#', LIMIT => 50}
```
