# Corrections appliquées au script de chargement du cours (Neo4j_projet)
# avant son exécution dans cypher-shell :
#   sed -f corriger_chargement.sed Neo4j_projet/script_chargement.cypher | cypher-shell ...
# 1. cypher-shell ne reconnaît pas le préfixe :auto de Neo4j Browser.
s/^:auto //
# 2. Le numéro d'article order_item_id recommence à 1 dans chaque commande :
#    un article est identifié par la paire (order_id, order_item_id).
s/REQUIRE oi\.order_item_id IS UNIQUE/REQUIRE (oi.order_id, oi.order_item_id) IS UNIQUE/
s/{order_item_id: row\.order_item_id}/{order_id: row.order_id, order_item_id: row.order_item_id}/
