# Chapitre 5 : exemples de code du livre

Ce fichier reprend, dans l’ordre du chapitre, les blocs de code du livre « Les bases de données modernes ». Copiez-les plutôt que de les retaper. Le titre de section et la phrase qui précède chaque bloc vous aident à les situer.


## 5.1 Introduction

> Voici un exemple simple de l’utilisation du chiffre associé à un type de données. Prenez par exemple la requête suivante :

```
// un document d’exemple, pour que la requête retourne un résultat
db.employes.insertOne({ prénom: "Auguste", nom: "Lariche" })
db.employes.find({ prénom: { $type: 2 } }, { prénom: 1, _id: 0 })
```


## 5.2.1 Imbriquer ou référencer

> Option 1 : imbriquer. Le document de l’auteur devient la valeur d’un champ du livre. Ce sous-document fonctionne exactement comme le champ prix de la section 5.3.1, qui contient lui-même les champs valeur et devise. Une seule lecture suffit pour afficher le livre avec son auteur, et la notation poin…

```
use modele_imbrique
db.livres.insertOne({ _id: 1, titre: "XQuery", pages: 746,
  auteur: { prenom: "Auguste", nom: "Lariche" } })
db.livres.find({ "auteur.nom": "Lariche" })
```

> Option 2 : référencer. L’auteur est stocké une seule fois dans la collection auteurs, et le livre ne garde que son identifiant dans le champ auteur_id, un peu comme une clé étrangère. Pour afficher le livre avec son auteur, il faut maintenant réunir les deux documents. L’application peut faire deux …

```
use modele_reference
db.auteurs.insertOne({ _id: 100, prenom: "Auguste", nom: "Lariche" })
db.livres.insertOne({ _id: 1, titre: "XQuery", pages: 746,
  auteur_id: 100 })
db.livres.aggregate([ { $lookup: {
  from: "auteurs", localField: "auteur_id",
  foreignField: "_id", as: "auteur" } } ])
```


## 5.2.2 Exemples de décisions de modélisation selon les relations

> Tous les exemples de cette section s’exécutent dans une base nommée modeles. Ils utilisent des identifiants lisibles (« u1 », « p3077 », etc.) plutôt que des ObjectId, pour que les références soient faciles à suivre.

```
use modeles
db.utilisateurs.insertOne({ _id: "u1",
  nom: "Auguste Lariche",
  compagnie: "Agilent",
  X: "@lariche",
  twitch: "pariche",
  tiktok: "@lar1che",
  linkedin: "linkedin.com/in/larichev",
  siteWeb: "www.ville-lariche.fr" })
```

> Pour les relations 1:(petit)n où il y a peu de dépendants n, les paires clé-valeurs par défaut sont aussi utilisées et l’imbrication est préférée. La règle générale ici est que « vous devez favoriser l’imbrication à moins d’avoir une bonne raison de ne pas le faire » (voir l’exemple suivant) :

```
db.utilisateurs.updateOne({ _id: "u1" }, { $set: { adresses: [
  { rue: "Place du Maréchal Leclerc", ville: "La Riche",
    pays: "France" },
  { rue: "16 Rue Brey", ville: "Paris", pays: "France" } ] } })
db.utilisateurs.findOne({ _id: "u1" })
```

> Maintenant, avec un schéma qui pourrait potentiellement enregistrer des milliers de sous-pièces, nous n’avons probablement pas besoin d’avoir toutes les données pour ces détails à chaque requête, mais il est toujours important que cette relation soit maintenue dans notre schéma. Ainsi, nous pourrion…

```
// collection produits : le parent garde un tableau d’identifiants
db.produits.insertOne({ _id: "p3077",
  nom: "Vélo de course 3077",
  manufacturier: "Pierre Perrin",
  catalogue: 6543,
  pièces: ["frein-arrière", "frein-avant", "pédale",
           "pignon", "bielle", "plateaux"] })
// collection pieces : un document par pièce
db.pieces.insertOne({ _id: "frein-arrière",
  numéro: 54987,
  nom: "kit complet pour frein arrière",
  quantité: 65,
  coût: 5.55,
  prix: 21.99 })
// joindre le produit et le détail de ses pièces
db.produits.aggregate([ { $lookup: { from: "pieces",
  localField: "pièces", foreignField: "_id", as: "détails" } } ])
```

> Avec MongoDB, la quantité maximale de données dans un document est limitée. Imbriquer tous les messages dans le document du serveur serait dangereux, car nous pourrions potentiellement atteindre la limite de 16 Mo par document. N’importe quel serveur peut générer suffisamment de messages pour dépass…

```
// collection serveurs
db.serveurs.insertOne({ _id: "AA", nom: "Harmonie",
  ip: "127.66.77.88" })
// collection journal : chaque message garde l’identifiant du serveur
db.journal.insertOne({ horloge: ISODate("2025-12-28T09:42:41.382Z"),
  message: "cpu arrêté", serveur: "AA" })
db.journal.find({ serveur: "AA" })
```

> Afin de préserver ces relations entre les utilisateurs et les tâches, il faudra qu’il y ait des références d’un utilisateur aux nombreuses tâches et des références d’une tâche aux nombreux utilisateurs. Voyons comment cela pourrait fonctionner pour une application de liste de tâches.

```
// collection utilisateurs : chaque utilisateur référence ses tâches
db.utilisateurs.insertOne({ _id: "u2", nom: "Michelin Lecours",
  tâches: ["t1", "t2"] })
// collection taches : chaque tâche référence ses responsables
db.taches.insertMany([
  { _id: "t1", description: "effectuer les tests de performance",
    date_due: ISODate("2025-12-28"), responsables: ["u2", "u3"] },
  { _id: "t2", description: "rédiger le rapport de tests",
    date_due: ISODate("2026-01-15"), responsables: ["u2"] } ])
db.taches.find({ responsables: "u2" }, { description: 1 })
```


## 5.3 Installer MongoDB et utiliser le shell mongosh

> L’image officielle mongo contient le serveur et le shell mongosh. Le fichier compose.yaml du dossier ch05-mongodb démarre le serveur, nommé mongo, sur le port 27017 :

```
% cd bd-modernes/ch05-mongodb
% docker compose up -d
% docker exec -it mongo mongosh
```

> Sans le dépôt, la commande suivante démarre le même conteneur :

```
% docker run -d --name mongo -p 27017:27017 mongo:9.0
```

> La commande suivante affiche la version du serveur :

```
% docker exec -it mongo mongosh --quiet --eval "db.version()"
```

> Le résultat attendu est le suivant :

```
9.0.4
```

> Les bases de ce chapitre (employee, librairie et club) sont créées par les commandes du chapitre lui-même. Le fichier exemples_du_livre.md du dossier les reprend toutes, dans l’ordre, pour que vous puissiez les copier. Pour l’exemple Mongoose, installez les dépendances du dossier node :

```
% cd node && npm install
```

> Lorsque vous aurez terminé les exemples du chapitre, les commandes suivantes libèrent les ressources :

```
% docker compose down -v
```

> Créons d’abord une BD nommée employee :

```
use employee
```

> et la réponse :

```
switched to db employee
```

> Attention : MongoDB ne crée réellement une base de données qu’au moment où vous y insérez un premier document. Si vous exécutez show dbs maintenant, employee n’apparaît pas encore dans la liste. Ajoutons donc d’abord un enregistrement avec mon nom :

```
db.employee.insertOne({"Nom":"Auguste Lariche"})
```

> et la réponse :

```
{
  acknowledged: true,
  insertedId: ObjectId('67b3eb8c4013dc72202a88f0')
}
```

> Vérifions maintenant que la base de données existe :

```
show dbs
```

> et la réponse (les tailles varient d’une installation à l’autre) :

```
admin      40.00 KiB
config    108.00 KiB
employee    8.00 KiB
local      40.00 KiB
```

> Vous pouvez aussi insérer plusieurs documents à l’aide de la méthode db.employee.insertMany. Pour lire cette base de données, utilisez l’énoncé db.employee.find({}), qui retourne :

```
{
  _id: ObjectId('67b3eb8c4013dc72202a88f0'),
  Nom: 'Auguste Lariche'
}
```


## 5.3.1 BD, collections et documents

> Faisons un autre exemple. Créez la base de données « librairie » :

```
use librairie
```

> Ensuite créons une collection de documents « Livres » dans cette base de données : 

```
db.createCollection("Livres")
```

> Maintenant nous allons insérer 6 livres dans cette collection :

```
db.Livres.insertMany([
{"titre":"XQuery", "pages": 746, "lang":"en", "prix": {
"valeur" : 42.99, "devise" : "$",}},
{"titre":"DataAlgorithms","pages": 778, "lang":"en", "prix": {
"valeur" : 59.99, "devise" : "$",}},
{"titre":"Redis Essentials","pages": 230,"lang":"en","prix": {
"valeur" : 31.99, "devise" : "$",}},
{"titre":"MongoDB Data Modeling","pages": 202,"lang":"en","prix": {
"valeur" : 19.99,"devise" : "$",}},
{"titre":"Hadoop Security","pages": 746,"lang":"en","prix": {
"valeur" : 42.99, "devise" : "$",}},
{"titre":"Think Agile", "pages": 224, "lang":"en", "prix": {
"valeur" : 18.95, "devise" : "$",}
}])
```

> Et le système répond :

```
acknowledged: true,
  insertedIds: {
    '0': ObjectId('67b73b284013dc72202a88f1'),
    '1': ObjectId('67b73b284013dc72202a88f2'),
    '2': ObjectId('67b73b284013dc72202a88f3'),
    '3': ObjectId('67b73b284013dc72202a88f4'),
    '4': ObjectId('67b73b284013dc72202a88f5'),
    '5': ObjectId('67b73b284013dc72202a88f6')
    }
 }
```

> Finalement nous allons créer une autre collection « auteurs » et insérer un seul document :

```
db.createCollection("Auteurs")
db.Auteurs.insertOne({Prénom :"Auguste", Nom :"Lariche"})
```

> Vous pouvez consulter les collections d’une base de données à l’aide de l’énoncé suivant :  

```
db.getCollectionNames()
```

> et le système répond :

```
[ 'Auteurs', 'Livres' ]
```

> Vous pouvez finalement détruire cette base de données à l’aide de l’énoncé suivant :

```
db.dropDatabase()

```


## 5.4.1 Insérer des documents

> Créez la base de données et insérez les livres à l’aide de insertMany. Notez que nous fournissons nous-mêmes la valeur de _id; si on l’omet, MongoDB génère automatiquement un ObjectId :

```
use librairie
db.livres.insertMany([
  { _id: "b1", titre: "Initiation à MongoDB",
    auteurs: ["L. Côté"], année: 2021,
    prix: { valeur: 42, devise: "CAD" },
    catégories: ["NoSQL", "Documents"], stock: 12 },
  { _id: "b2", titre: "Maîtriser SQL",
    auteurs: ["M. Roy", "A. Diallo"], année: 2019,
    prix: { valeur: 55, devise: "CAD" },
    catégories: ["Relationnel"], stock: 4 },
  { _id: "b3", titre: "Modélisation NoSQL",
    auteurs: ["L. Côté"], année: 2023,
    prix: { valeur: 38, devise: "CAD" },
    catégories: ["NoSQL"], stock: 0 },
  { _id: "b4", titre: "Mégadonnées et Hadoop",
    année: 2017, prix: { valeur: 29, devise: "CAD" },
    catégories: ["Mégadonnées"], stock: 7 },
  { _id: "b5", titre: "Python pour les données",
    auteurs: ["S. Martin"], année: 2022,
    prix: { valeur: 24, devise: "CAD" },
    catégories: ["Programmation"], stock: 30 },
  { _id: "b6", titre: "Graphes et réseaux",
    auteurs: ["P. Lévesque"], année: 2020,
    prix: { valeur: 47, devise: "CAD" },
    catégories: ["NoSQL", "Graphes"], stock: 3 },
  { _id: "b7", titre: "Mémoire vive et caches",
    auteurs: ["D. Moulla"], année: 2024,
    prix: { valeur: 19, devise: "CAD" },
    catégories: ["NoSQL", "Clé-valeur"], stock: 15 }
])
```

> Le livre b4 n’a volontairement pas de champ auteurs : dans une collection, deux documents n’ont pas à avoir la même structure. Insérez ensuite quelques commandes. Chaque commande imbrique ses lignes de commande, qui font référence aux livres par leur identifiant :

```
db.commandes.insertMany([
  { _id: "c1", client: "Julie Tremblay",
    date: ISODate("2015-09-02"),
    lignes: [ { livre: "b4", qté: 1, prix: 29 },
              { livre: "b2", qté: 1, prix: 55 } ] },
  { _id: "c2", client: "Minh Nguyen",
    date: ISODate("2015-11-20"),
    lignes: [ { livre: "b7", qté: 2, prix: 19 } ] },
  { _id: "c3", client: "Julie Tremblay",
    date: ISODate("2016-01-15"),
    lignes: [ { livre: "b1", qté: 1, prix: 42 },
              { livre: "b5", qté: 3, prix: 24 } ] }
])
```


## 5.4.2 Mettre à jour des documents

> Une mise à jour comporte deux parties : un filtre, qui désigne les documents à modifier, et un document de mise à jour, qui utilise des opérateurs pour décrire la modification. La méthode updateOne modifie le premier document qui correspond au filtre; updateMany les modifie tous :

```
// changer la valeur d’un champ
db.livres.updateOne({ _id: "b3" }, { $set: { stock: 20 } })

// augmenter de 10 % le prix de tous les livres NoSQL
db.livres.updateMany({ catégories: "NoSQL" },
                     { $mul: { "prix.valeur": 1.10 } })

// retirer un champ et en ajouter un autre
db.livres.updateOne({ _id: "b5" },
                    { $unset: { stock: "" },
                      $set:   { épuisé: false } })
```

> La notation pointée ("prix.valeur") atteint un champ d’un sous-document. L’option upsert: true crée le document s’il n’existe pas, ce qui évite de devoir tester son existence au préalable. Enfin, chaque mise à jour d’un document unique est atomique, même lorsqu’elle modifie plusieurs champs et des s…

```
db.livres.updateOne({ _id: "b6" },
                    { $push: { catégories: "Algorithmes" },
                      $inc:  { stock: -1 } })
```


## 5.4.3 Supprimer des documents

> Les méthodes deleteOne et deleteMany suppriment les documents qui correspondent à un filtre. Un filtre vide supprime tous les documents de la collection, mais la collection et ses index existent toujours; la méthode drop supprime la collection elle-même :

```
db.livres.deleteOne({ _id: "b3" })
db.commandes.deleteMany({ date: { $lt: ISODate("2015-01-01") } })
db.commandes.drop()          // supprime toute la collection
```


## 5.5 Les requêtes et les projections

> La méthode find reçoit deux paramètres : un filtre, qui sélectionne les documents, et une projection, qui choisit les champs retournés. La projection joue le même rôle que la liste des colonnes après SELECT en SQL : la valeur 1 inclut un champ, la valeur 0 l’exclut. Le champ _id est toujours retourn…

```
// SELECT titre, prix FROM livres
db.livres.find({}, { titre: 1, "prix.valeur": 1, _id: 0 })
```


## 5.5.1 Opérateurs de comparaison ($eq, $gt, $gte, $lt, $lte, $ne, $in et $nin)

> Lister le titre et le prix de tous les livres, puis trouver un livre précis :

```
db.livres.find({}, { titre: 1, prix: 1 })
db.livres.find({ titre: "Maîtriser SQL" })
```

> Identifier les commandes qui contiennent le livre b7. Lorsque le champ est un tableau de sous-documents, la notation pointée cherche dans tous les éléments du tableau :

```
db.commandes.find({ "lignes.livre": "b7" })
```

> Trouver les livres qui coûtent plus de 30 $ :

```
db.livres.find({ "prix.valeur": { $gt: 30 } },
               { titre: 1, prix: 1 })
```

> Trouver les trois livres les moins chers, puis lister tous les titres et prix par prix décroissant :

```
db.livres.find({}, { titre: 1, prix: 1 }).
         sort({ "prix.valeur": 1 }).limit(3)
db.livres.find({}, { titre: 1, prix: 1 }).
         sort({ "prix.valeur": -1 })
```


## 5.5.2 Les opérateurs logiques ($or, $and, $not et $nor)

> Lister les livres dont le prix est compris entre 20 $ et 40 $ :

```
db.livres.find({ "prix.valeur": { $gte: 20, $lte: 40 } })
```

> Trouver les commandes passées avant le 15 octobre 2015, en utilisant $not (c’est-à-dire les commandes dont la date n’est pas postérieure ou égale à cette date) :

```
db.commandes.find(
  { date: { $not: { $gte: ISODate("2015-10-15") } } })
```

> Trouver les commandes qui contiennent le livre b4 ou le livre b7, d’abord avec $or, puis avec la forme équivalente et plus concise $in :

```
db.commandes.find({ $or: [ { "lignes.livre": "b4" },
                           { "lignes.livre": "b7" } ] })
db.commandes.find({ "lignes.livre": { $in: ["b4", "b7"] } })
```


## 5.5.3 L’opérateur de présence ($exists)

> Comme les documents d’une collection n’ont pas tous la même structure, on doit parfois chercher les documents qui possèdent, ou non, un champ donné. C’est le rôle de l’opérateur $exists :

```
db.livres.find({ auteurs: { $exists: true } }, { titre: 1 })
db.livres.find({ auteurs: { $exists: false } }, { titre: 1 })
```


## 5.5.4 Recherche en texte libre (createIndex, $text)

> Avant d’effectuer une recherche en texte libre, il faut créer un index de texte. Sans cet index, l’opérateur $text est refusé. L’index découpe le texte en mots, retire les mots vides de la langue indiquée et réduit chaque mot à sa racine, de sorte que « données » trouve aussi « donnée ». Une collect…

```
db.livres.createIndex({ titre: "text" },
                      { default_language: "french" })
db.livres.find({ $text: { $search: "données graphes" } },
               { titre: 1, score: { $meta: "textScore" } }).
         sort({ score: { $meta: "textScore" } })
```


## 5.5.5 L’opérateur JavaScript ($where) et son remplaçant ($expr)

> L’opérateur $where évalue une expression JavaScript pour chaque document; le mot-clé this désigne le document courant. Par exemple, pour trouver les livres de moins de 30 $ ou ceux dont le titre commence par la lettre M :

```
db.livres.find({ $where: "this.prix.valeur < 30" })
db.livres.find({ $where: function () {
                   return this.titre.startsWith("M"); } })
```

> Cet opérateur est cependant à éviter. Il ne peut pas utiliser d’index, il exécute du code JavaScript pour chaque document de la collection, et il est déprécié depuis MongoDB 8.0, comme les autres fonctions JavaScript exécutées par le serveur ($function et $accumulator) ; un administrateur peut d’ail…

```
db.livres.find({ $expr: { $lt: ["$prix.valeur", 30] } })
db.livres.find({ titre: /^M/ })
```


## 5.6.1 Pipeline d’agrégation ($match, $project, $group, $unwind, $lookup, $sort, $limit, $skip)

> Le pipeline d’agrégation utilise souvent l’opérateur $match qui filtre les documents. Cet opérateur filtre les documents d’une collection qui rencontrent une condition particulière. La commande est structurée de cette manière :

```
db.nomDeCollection.aggregate([ { $match: { <requête> } } ])
```

> Les éléments entre < et > sont à remplacer par vos propres valeurs. Par exemple, pour garder seulement les livres dont le stock dépasse 5 :

```
db.livres.aggregate([ { $match: { stock: { $gt: 5 } } } ])
```

> Un autre opérateur pour l’agrégation est le $group. Cet opérateur sépare les documents en groupes, en fonction d’une « clé de groupe ». Le résultat est un document pour chaque clé de groupe unique. Une clé de groupe est souvent un champ ou un groupe de champs. La clé de groupe peut également être le…

```
db.nomDeCollection.aggregate([ { $group: {
  _id: <clé de groupe>,
  <champ>: { <accumulateur>: <expression> } } } ])
```

> Par exemple, pour compter les livres et calculer leur prix moyen par devise :

```
db.livres.aggregate([ { $group: { _id: "$prix.devise",
  nombre: { $sum: 1 }, prixMoyen: { $avg: "$prix.valeur" } } } ])
```

> L’opérateur $sort a pour but de trier les documents en fonction d’une ou plusieurs propriétés de l’objet. Il peut les trier dans l’ordre croissant ou décroissant. Pour bénéficier des meilleures performances de MongoDB, il est fortement conseillé de créer un index qui couvre le tri.

```
L’opérateur $sort peut se placer n’importe où dans le pipeline ; il produit le même nombre de documents qu’il en reçoit.
```


## 5.6.2 Un pipeline complet

> Combinons maintenant ces opérateurs. La librairie veut connaître, pour chaque client, le montant total de ses achats et les titres achetés, en ordre décroissant de montant. Les données nécessaires sont réparties entre deux collections : il faut défaire les lignes de commande, joindre les livres, pui…

```
db.commandes.aggregate([
  { $match:  { date: { $gte: ISODate("2015-01-01") } } },
  { $unwind: "$lignes" },
  { $lookup: { from: "livres", localField: "lignes.livre",
               foreignField: "_id", as: "livre" } },
  { $unwind: "$livre" },
  { $group:  { _id: "$client",
               total:  { $sum: { $multiply:
                         ["$lignes.qté", "$lignes.prix"] } },
               titres: { $addToSet: "$livre.titre" } } },
  { $sort:   { total: -1 } },
  { $project: { _id: 0, client: "$_id",
                total: "$total", titres: "$titres" } }
])
```

> Le résultat pour nos données est le suivant :

```
{ client: "Julie Tremblay", total: 198,
  titres: ["Mégadonnées et Hadoop", "Maîtriser SQL",
           "Initiation à MongoDB", "Python pour les données"] }
{ client: "Minh Nguyen", total: 38,
  titres: ["Mémoire vive et caches"] }
```


## 5.6.3 Index et analyse de performance

> Comme dans une BD relationnelle, une requête sans index doit parcourir toute la collection. La méthode explain montre le plan choisi par MongoDB : l’étape COLLSCAN indique un parcours complet, l’étape IXSCAN l’utilisation d’un index.

```
db.commandes.find({ client: "Julie Tremblay" }).
            explain("executionStats")
```

> Le point placé à la fin de la ligne indique au shell que la commande continue sur la ligne suivante. Une ligne qui commence par un point serait refusée par mongosh (« Invalid REPL keyword »).

```
db.commandes.createIndex({ client: 1, date: -1 })
```


## 5.6.4 Accéder à MongoDB avec Mongoose

> Le chapitre 3 a présenté les ORM pour les BD relationnelles. Pour MongoDB, l’équivalent dans l’écosystème Node.js est Mongoose, un ODM (Object Document Mapper). Mongoose ajoute à MongoDB ce que la base ne fournit pas elle-même : un schéma déclaré dans le code, la validation des données, des valeurs …

```
import mongoose from "mongoose";
await mongoose.connect("mongodb://localhost:27017/librairie");

const livreSchema = new mongoose.Schema({
  _id:        String,
  titre:      { type: String, required: true },
  auteurs:    [String],
  année:      { type: Number, min: 1450 },
  prix:       { valeur: { type: Number, min: 0 }, devise: String },
  catégories: [String],
  stock:      { type: Number, default: 0 },
});
const Livre = mongoose.model("Livre", livreSchema, "livres");

const pasChers = await Livre.find({ "prix.valeur": { $lt: 30 } })
                            .sort({ "prix.valeur": 1 })
                            .select("titre prix");
console.log(pasChers);
await mongoose.disconnect();
```


## 5.7.2 Réplication avec les jeux de répliques

> Par exemple, l’application du club peut exiger une confirmation majoritaire pour les réservations, puisqu’une réservation perdue serait inacceptable, tout en lisant le catalogue des activités sur le membre le plus proche :

```
db.reservations.insertOne(
  { membre_id: 27, activite_id: 3,
    debut: ISODate("2023-09-14T18:00:00Z"), demi_heures: 2 },
  { writeConcern: { w: "majority" } }
)
db.activites.find().readPref("nearest")
```


## 5.7.3 Mise à l’échelle horizontale par fragmentation (sharding)

> Pour la collection des réservations du club, une clé composée de l’identifiant du membre et de la date de début répartit bien les écritures entre les membres, tout en gardant ciblée la requête la plus fréquente, qui recherche les réservations d’un membre :

```
sh.shardCollection("club.reservations", { membre_id: 1, debut: 1 })
db.reservations.find({ membre_id: 27 })   // requête ciblée
db.reservations.find({ activite_id: 3 })  // diffusée à tous les fragments
```


## 5.8.2 Créer les collections et insérer les données

> Le script suivant crée les activités, puis un index unique qui empêche un membre de s’inscrire deux fois à la même activité :

```
use club
db.activites.insertMany([
  { _id: 3, nom: "Tennis de table", categorie: "raquette",
    capacite: 12, inscrits: 0,
    horaires: [ { jour: "lundi", debut: "18:00" },
                { jour: "jeudi", debut: "19:30" } ] },
  { _id: 7, nom: "Badminton", categorie: "raquette",
    capacite: 2, inscrits: 0,
    horaires: [ { jour: "mardi", debut: "18:30" } ] },
  { _id: 9, nom: "Yoga", categorie: "bien-être",
    capacite: 20, inscrits: 0,
    horaires: [ { jour: "samedi", debut: "10:00" } ] }
])
db.inscriptions.createIndex(
  { membre_id: 1, activite_id: 1 }, { unique: true })
```

> L’inscription doit respecter la capacité, même si deux membres réservent la dernière place au même instant. Le filtre de updateOne contient la condition « il reste une place », exprimée avec $expr : la vérification et l’incrément se font dans la même opération atomique, et la mise à jour ne modifie …

```
function inscrire(membre, act) {
  const r = db.activites.updateOne(
    { _id: act,
      $expr: { $lt: ["$inscrits", "$capacite"] } },
    { $inc: { inscrits: 1 } })
  if (r.modifiedCount === 0) return "complet"
  try {
    db.inscriptions.insertOne({ membre_id: membre,
      activite_id: act, date: new Date() })
    return "inscrit"
  } catch (e) {
    db.activites.updateOne({ _id: act },
                           { $inc: { inscrits: -1 } })
    return "déjà inscrit"
  }
}
inscrire(27, 7)   // inscrit
inscrire(58, 7)   // inscrit
inscrire(31, 7)   // complet : la capacité est de 2
inscrire(27, 3)   // inscrit
inscrire(27, 3)   // déjà inscrit
inscrire(31, 9)   // inscrit
```


## 5.8.3 Interroger les données

> La requête R1 se fait en une seule lecture. La projection calcule le nombre de places restantes à partir des deux champs du document :

```
db.activites.find({ _id: 3 },
  { nom: 1, horaires: 1,
    restantes: { $subtract: ["$capacite", "$inscrits"] } })
// { _id: 3, nom: 'Tennis de table',
//   horaires: [ { jour: 'lundi', debut: '18:00' },
//               { jour: 'jeudi', debut: '19:30' } ],
//   restantes: 11 }
```

> La requête R2 part des inscriptions du membre et va chercher chaque activité avec $lookup, une jointure ciblée sur la clé primaire des activités :

```
db.inscriptions.aggregate([
  { $match: { membre_id: 27 } },
  { $lookup: { from: "activites", localField: "activite_id",
               foreignField: "_id", as: "a" } },
  { $unwind: "$a" },
  { $project: { _id: 0, activite: "$a.nom",
                horaires: "$a.horaires" } },
  { $sort: { activite: 1 } }
])
// { activite: 'Badminton', horaires: [ ... ] }
// { activite: 'Tennis de table', horaires: [ ... ] }
```

> La requête R3 regroupe les activités par catégorie et calcule le taux de remplissage, arrondi à une décimale :

```
db.activites.aggregate([
  { $group: { _id: "$categorie",
              inscrits: { $sum: "$inscrits" },
              capacite: { $sum: "$capacite" } } },
  { $project: { taux: { $round: [ { $multiply: [100,
      { $divide: ["$inscrits", "$capacite"] }] }, 1] } } },
  { $sort: { taux: -1 } }
])
// { _id: 'raquette', taux: 21.4 }
// { _id: 'bien-être', taux: 5 }
```
