#!/bin/bash
# Vérification du chapitre 9 (HBase) : exécute les commandes du livre et enregistre les sorties.
# À lancer depuis le dossier de HBase (par exemple ~/hbase-2.6.7), avec HBase arrêté :
#   bash ~/Desktop/verif_chapitre9.sh
# Résultat : ~/Desktop/resultats_chapitre9.txt

SORTIE="$HOME/Desktop/resultats_chapitre9.txt"
exec > >(tee "$SORTIE") 2>&1

titre() { echo; echo "=================== $1"; }

titre "Environnement"
sw_vers 2>/dev/null | head -2
java -version 2>&1 | head -1
echo "Dossier : $PWD"
ls bin/hbase >/dev/null 2>&1 || { echo "ERREUR : lancez ce script depuis le dossier de HBase."; exit 1; }
bin/hbase version 2>/dev/null | head -1

titre "Configuration Snappy (section 9.6)"
if grep -q "hbase.io.compress.snappy.codec" conf/hbase-site.xml; then
  echo "Propriété déjà présente."
else
  cp conf/hbase-site.xml conf/hbase-site.xml.avant-chapitre9
  perl -0pi -e 's#</configuration>#  <property>\n    <name>hbase.io.compress.snappy.codec</name>\n    <value>org.apache.hadoop.hbase.io.compress.xerial.SnappyCodec</value>\n  </property>\n</configuration>#' conf/hbase-site.xml
  echo "Propriété ajoutée (copie de l'original : conf/hbase-site.xml.avant-chapitre9)."
fi
grep -A1 "snappy.codec" conf/hbase-site.xml

titre "Départ propre : arrêt, effacement des données de test, démarrage"
bin/stop-hbase.sh >/dev/null 2>&1
rm -rf tmp/hbase tmp/zookeeper
bin/start-hbase.sh
sleep 25

titre "9.3 status"
bin/hbase shell <<'EOF'
status
EOF

titre "9.2.3 Table large"
bin/hbase shell <<'EOF'
create 'passages_large', 'p'
put 'passages_large', 'membre#0027', 'p:9223370305315675807', 'T07'
put 'passages_large', 'membre#0027', 'p:9223370305404175807', 'T03'
get 'passages_large', 'membre#0027'
EOF

titre "9.4.1 à 9.4.4 Shell"
bin/hbase shell <<'EOF'
create 'membres', {NAME => 'info', VERSIONS => 1}, {NAME => 'activite', VERSIONS => 3, TTL => 31536000}
describe 'membres'
list
put 'membres', 'membre#0027', 'info:nom', 'Tremblay'
put 'membres', 'membre#0027', 'info:prenom', 'Julie'
put 'membres', 'membre#0027', 'activite:tennis', '14'
put 'membres', 'membre#0027', 'activite:tennis', '15'
put 'membres', 'membre#0027', 'activite:tennis', '16'
put 'membres', 'membre#0044', 'info:nom', 'Nguyen'
get 'membres', 'membre#0027'
get 'membres', 'membre#0027', 'info'
get 'membres', 'membre#0027', {COLUMN => 'activite:tennis', VERSIONS => 3}
incr 'membres', 'membre#0027', 'activite:tennis', 1
incr 'membres', 'membre#0027', 'activite:squash', 1
get_counter 'membres', 'membre#0027', 'activite:squash'
scan 'membres', {STARTROW => 'membre#0020', STOPROW => 'membre#0050'}
scan 'membres', {ROWPREFIXFILTER => 'membre#00', COLUMNS => ['info:nom'], LIMIT => 10}
scan 'membres', {FILTER => "SingleColumnValueFilter('info','nom',=,'binary:Tremblay')"}
put 'membres', 'membre#0027', 'activite:escalade', '2'
put 'membres', 'membre#0027', 'sante:allergies', 'aucune'
put 'membres', 'membre#0027', 'activite:tennis', '17'
get 'membres', 'membre#0027', {COLUMN => 'activite:tennis', VERSIONS => 5}
put 'membres', 'membre#100', 'info:nom', 'Roy'
put 'membres', 'membre#27', 'info:nom', 'Lavoie'
scan 'membres', {COLUMNS => ['info:nom']}
deleteall 'membres', 'membre#100'
deleteall 'membres', 'membre#27'
EOF

titre "9.4.5 Fonctionnement interne"
bin/hbase shell <<'EOF'
scan 'hbase:meta', {ROWPREFIXFILTER => 'membres', COLUMNS => ['info:server']}
list_regions 'membres'
flush 'membres'
put 'membres', 'membre#0027', 'info:nom', 'Tremblay-Roy'
flush 'membres'
EOF
echo "--- fichiers de la famille info après deux flush"
ls tmp/hbase/data/default/membres/*/info/
bin/hbase shell <<'EOF'
major_compact 'membres'
EOF
sleep 20
echo "--- fichiers après le compactage majeur"
ls tmp/hbase/data/default/membres/*/info/
F=$(ls -t tmp/hbase/data/default/membres/*/info/* | head -1)
bin/hbase hfile -p -f "file://$PWD/$F" 2>/dev/null
echo "--- zkcli"
bin/hbase zkcli ls /hbase 2>&1 | tail -3

titre "9.4.6 Supprimer et modifier le schéma"
bin/hbase shell <<'EOF'
delete 'membres', 'membre#0027', 'activite:tennis'
deleteall 'membres', 'membre#0044'
alter 'membres', {NAME => 'preferences'} # ajoute une famille
count 'membres'
disable 'membres'
drop 'membres'
create 'membres', {NAME => 'info', VERSIONS => 1}, {NAME => 'activite', VERSIONS => 3, TTL => 31536000}
put 'membres', 'membre#0027', 'info:nom', 'Tremblay'
put 'membres', 'membre#0027', 'info:prenom', 'Julie'
put 'membres', 'membre#0027', 'activite:tennis', '14'
put 'membres', 'membre#0027', 'activite:tennis', '15'
put 'membres', 'membre#0027', 'activite:tennis', '16'
put 'membres', 'membre#0044', 'info:nom', 'Nguyen'
EOF

titre "9.5 Programme Java"
cat > Membres.java <<'EOF'
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
EOF
javac -cp "$(bin/hbase classpath)" Membres.java && java -cp "$(bin/hbase classpath):." Membres 2>&1 | grep -v "WARN\|INFO\|SLF4J"

titre "9.6 Étude de cas"
bin/hbase shell <<'EOF'
create 'passages_par_membre', {NAME => 'p', VERSIONS => 1, COMPRESSION => 'SNAPPY', TTL => 94608000}, {SPLITS => ['01','02','03','04','05','06','07','08','09','10','11','12','13','14','15']}
sel = '%02d' % (27 % 16)
inv = java.lang.Long::MAX_VALUE - Time.utc(2024, 11, 13, 23, 5).to_i * 1000
puts "#{sel}#0000027##{inv}"
put 'passages_par_membre', '11#0000027#9223370305315675807', 'p:tourniquet', 'T07'
put 'passages_par_membre', '11#0000027#9223370305315675807', 'p:site', 'Centre-ville'
put 'passages_par_membre', '11#0000027#9223370305315675807', 'p:sens', 'entree'
put 'passages_par_membre', '11#0000027#9223370305404175807', 'p:tourniquet', 'T03'
put 'passages_par_membre', '11#0000027#9223370305404175807', 'p:site', 'Rosemont'
put 'passages_par_membre', '11#0000027#9223370305404175807', 'p:sens', 'sortie'
scan 'passages_par_membre', {ROWPREFIXFILTER => '11#0000027#', LIMIT => 50}
list_regions 'passages_par_membre'
EOF

titre "A14 Exercice 9.3"
bin/hbase shell <<'EOF'
create 'reservations', {NAME => 'r', VERSIONS => 3}
put 'reservations', 'terrain07#20241114#1800', 'r:statut', 'DEMANDEE'
put 'reservations', 'terrain07#20241114#1800', 'r:statut', 'CONFIRMEE'
put 'reservations', 'terrain07#20241114#1800', 'r:statut', 'PAYEE'
get 'reservations', 'terrain07#20241114#1800', {COLUMN => 'r:statut', VERSIONS => 3}
scan 'reservations', {ROWPREFIXFILTER => 'terrain07#20241114#'}
scan 'reservations', {STARTROW => 'terrain07#20241114#', STOPROW => 'terrain07#20241115#'}
EOF

titre "Fin"
bin/stop-hbase.sh
echo "Fichier écrit : $SORTIE"
