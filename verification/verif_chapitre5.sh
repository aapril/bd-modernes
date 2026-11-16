#!/usr/bin/env bash
# Généré pour « Les bases de données modernes ». Exécute les exemples du chapitre
# tels qu'ils figurent dans le livre et consigne les résultats dans resultats_chapitre5.txt.
# Usage : depuis le dossier verification du dépôt : ./verif_chapitre5.sh
cd "$(dirname "$0")/.."
OUT="$(pwd)/verification/resultats_chapitre5.txt"
exec > >(tee "$OUT") 2>&1
echo "# Chapitre 5 : MongoDB 9.0 ; $(date)"; echo "# $(uname -a)"; docker --version
attendre() { for i in $(seq 1 60); do eval "$1" >/dev/null 2>&1 && return 0; sleep 2; done; echo "!! service non prêt : $1"; }
bloc() { echo; echo "=================================================================="; echo "== $1"; echo "=================================================================="; }
cd ch05-mongodb && docker compose down -v >/dev/null 2>&1; docker compose up -d
attendre "docker exec mongo mongosh --quiet --eval 1"
bloc "Version"; docker exec mongo mongosh --quiet --eval "db.version()"
docker exec -i mongo mongosh --quiet <<'FIN_JS'
print('=== bloc 5-1 (5.1 Introduction)')
// un document d’exemple, pour que la requête retourne un résultat
db.employes.insertOne({ prénom: "Auguste", nom: "Lariche" })
db.employes.find({ prénom: { $type: 2 } }, { prénom: 1, _id: 0 })
print('=== bloc 5-2 (5.2.1 Imbriquer ou référencer)')
use modele_imbrique
db.livres.insertOne({ _id: 1, titre: "XQuery", pages: 746,
  auteur: { prenom: "Auguste", nom: "Lariche" } })
db.livres.find({ "auteur.nom": "Lariche" })
print('=== bloc 5-3 (5.2.1 Imbriquer ou référencer)')
use modele_reference
db.auteurs.insertOne({ _id: 100, prenom: "Auguste", nom: "Lariche" })
db.livres.insertOne({ _id: 1, titre: "XQuery", pages: 746,
  auteur_id: 100 })
db.livres.aggregate([ { $lookup: {
  from: "auteurs", localField: "auteur_id",
  foreignField: "_id", as: "auteur" } } ])
print('=== bloc 5-4 (5.2.2 Exemples de décisions de modélisation selon les relations)')
use modeles
db.utilisateurs.insertOne({ _id: "u1",
  nom: "Auguste Lariche",
  compagnie: "Agilent",
  X: "@lariche",
  twitch: "pariche",
  tiktok: "@lar1che",
  linkedin: "linkedin.com/in/larichev",
  siteWeb: "www.ville-lariche.fr" })
print('=== bloc 5-5 (5.2.2 Exemples de décisions de modélisation selon les relations)')
db.utilisateurs.updateOne({ _id: "u1" }, { $set: { adresses: [
  { rue: "Place du Maréchal Leclerc", ville: "La Riche",
    pays: "France" },
  { rue: "16 Rue Brey", ville: "Paris", pays: "France" } ] } })
db.utilisateurs.findOne({ _id: "u1" })
print('=== bloc 5-6 (5.2.2 Exemples de décisions de modélisation selon les relations)')
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
print('=== bloc 5-7 (5.2.2 Exemples de décisions de modélisation selon les relations)')
// collection serveurs
db.serveurs.insertOne({ _id: "AA", nom: "Harmonie",
  ip: "127.66.77.88" })
// collection journal : chaque message garde l’identifiant du serveur
db.journal.insertOne({ horloge: ISODate("2025-12-28T09:42:41.382Z"),
  message: "cpu arrêté", serveur: "AA" })
db.journal.find({ serveur: "AA" })
print('=== bloc 5-8 (5.2.2 Exemples de décisions de modélisation selon les relations)')
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
print('=== bloc 5-9 (5.3 Installer MongoDB et utiliser le shell mongosh)')
use employee
print('=== bloc 5-10 (5.3 Installer MongoDB et utiliser le shell mongosh)')
db.employee.insertOne({"Nom":"Auguste Lariche"})
print('=== bloc 5-11 (5.3 Installer MongoDB et utiliser le shell mongosh)')
show dbs
print('=== bloc 5-12 (5.3.1 BD, collections et documents)')
use librairie
print('=== bloc 5-13 (5.3.1 BD, collections et documents)')
db.createCollection("Livres")
print('=== bloc 5-14 (5.3.1 BD, collections et documents)')
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
print('=== bloc 5-15 (5.3.1 BD, collections et documents)')
db.createCollection("Auteurs")
db.Auteurs.insertOne({Prénom :"Auguste", Nom :"Lariche"})
print('=== bloc 5-16 (5.3.1 BD, collections et documents)')
db.getCollectionNames()
print('=== bloc 5-17 (5.3.1 BD, collections et documents)')
db.dropDatabase()
print('=== bloc 5-18 (5.4.1 Insérer des documents)')
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
print('=== bloc 5-19 (5.4.1 Insérer des documents)')
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
print('=== bloc 5-20 (5.4.2 Mettre à jour des documents)')
// changer la valeur d’un champ
db.livres.updateOne({ _id: "b3" }, { $set: { stock: 20 } })

// augmenter de 10 % le prix de tous les livres NoSQL
db.livres.updateMany({ catégories: "NoSQL" },
                     { $mul: { "prix.valeur": 1.10 } })

// retirer un champ et en ajouter un autre
db.livres.updateOne({ _id: "b5" },
                    { $unset: { stock: "" },
                      $set:   { épuisé: false } })
print('=== bloc 5-21 (5.4.2 Mettre à jour des documents)')
db.livres.updateOne({ _id: "b6" },
                    { $push: { catégories: "Algorithmes" },
                      $inc:  { stock: -1 } })
print('=== bloc 5-22 (5.4.3 Supprimer des documents)')
db.livres.deleteOne({ _id: "b3" })
db.commandes.deleteMany({ date: { $lt: ISODate("2015-01-01") } })
db.commandes.drop()          // supprime toute la collection
print('=== bloc 5-23 (5.5 Les requêtes et les projections)')
// SELECT titre, prix FROM livres
db.livres.find({}, { titre: 1, "prix.valeur": 1, _id: 0 })
print('=== bloc 5-24 (5.5.1 Opérateurs de comparaison (eq, gt, gte, lt, lte, ne, in et nin))')
db.livres.find({}, { titre: 1, prix: 1 })
db.livres.find({ titre: "Maîtriser SQL" })
print('=== bloc 5-25 (5.5.1 Opérateurs de comparaison (eq, gt, gte, lt, lte, ne, in et nin))')
db.commandes.find({ "lignes.livre": "b7" })
print('=== bloc 5-26 (5.5.1 Opérateurs de comparaison (eq, gt, gte, lt, lte, ne, in et nin))')
db.livres.find({ "prix.valeur": { $gt: 30 } },
               { titre: 1, prix: 1 })
print('=== bloc 5-27 (5.5.1 Opérateurs de comparaison (eq, gt, gte, lt, lte, ne, in et nin))')
db.livres.find({}, { titre: 1, prix: 1 }).
         sort({ "prix.valeur": 1 }).limit(3)
db.livres.find({}, { titre: 1, prix: 1 }).
         sort({ "prix.valeur": -1 })
print('=== bloc 5-28 (5.5.2 Les opérateurs logiques (or, and, not et nor))')
db.livres.find({ "prix.valeur": { $gte: 20, $lte: 40 } })
print('=== bloc 5-29 (5.5.2 Les opérateurs logiques (or, and, not et nor))')
db.commandes.find(
  { date: { $not: { $gte: ISODate("2015-10-15") } } })
print('=== bloc 5-30 (5.5.2 Les opérateurs logiques (or, and, not et nor))')
db.commandes.find({ $or: [ { "lignes.livre": "b4" },
                           { "lignes.livre": "b7" } ] })
db.commandes.find({ "lignes.livre": { $in: ["b4", "b7"] } })
print('=== bloc 5-31 (5.5.3 L’opérateur de présence (exists))')
db.livres.find({ auteurs: { $exists: true } }, { titre: 1 })
db.livres.find({ auteurs: { $exists: false } }, { titre: 1 })
print('=== bloc 5-32 (5.5.4 Recherche en texte libre (createIndex, text))')
db.livres.createIndex({ titre: "text" },
                      { default_language: "french" })
db.livres.find({ $text: { $search: "données graphes" } },
               { titre: 1, score: { $meta: "textScore" } }).
         sort({ score: { $meta: "textScore" } })
print('=== bloc 5-33 (5.5.5 L’opérateur JavaScript (where) et son remplaçant (expr))')
db.livres.find({ $where: "this.prix.valeur < 30" })
db.livres.find({ $where: function () {
                   return this.titre.startsWith("M"); } })
print('=== bloc 5-34 (5.5.5 L’opérateur JavaScript (where) et son remplaçant (expr))')
db.livres.find({ $expr: { $lt: ["$prix.valeur", 30] } })
db.livres.find({ titre: /^M/ })
print('=== bloc 5-35 (5.6.1 Pipeline d’agrégation (match, project, group, unwind, lookup, sort, limit, skip))')
db.nomDeCollection.aggregate([ { $match: { <requête> } } ])
print('=== bloc 5-36 (5.6.1 Pipeline d’agrégation (match, project, group, unwind, lookup, sort, limit, skip))')
db.livres.aggregate([ { $match: { stock: { $gt: 5 } } } ])
print('=== bloc 5-37 (5.6.1 Pipeline d’agrégation (match, project, group, unwind, lookup, sort, limit, skip))')
db.nomDeCollection.aggregate([ { $group: {
  _id: <clé de groupe>,
  <champ>: { <accumulateur>: <expression> } } } ])
print('=== bloc 5-38 (5.6.1 Pipeline d’agrégation (match, project, group, unwind, lookup, sort, limit, skip))')
db.livres.aggregate([ { $group: { _id: "$prix.devise",
  nombre: { $sum: 1 }, prixMoyen: { $avg: "$prix.valeur" } } } ])
print('=== bloc 5-39 (5.6.2 Un pipeline complet)')
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
print('=== bloc 5-40 (5.6.3 Index et analyse de performance)')
db.commandes.find({ client: "Julie Tremblay" }).
            explain("executionStats")
print('=== bloc 5-41 (5.6.3 Index et analyse de performance)')
db.commandes.createIndex({ client: 1, date: -1 })
print('=== bloc 5-42 (5.6.4 Accéder à MongoDB avec Mongoose)')
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
print('=== bloc 5-43 (5.7.2 Réplication avec les jeux de répliques)')
db.reservations.insertOne(
  { membre_id: 27, activite_id: 3,
    debut: ISODate("2023-09-14T18:00:00Z"), demi_heures: 2 },
  { writeConcern: { w: "majority" } }
)
db.activites.find().readPref("nearest")
print('=== bloc 5-44 (5.7.3 Mise à l’échelle horizontale par fragmentation (sharding))')
sh.shardCollection("club.reservations", { membre_id: 1, debut: 1 })
db.reservations.find({ membre_id: 27 })   // requête ciblée
db.reservations.find({ activite_id: 3 })  // diffusée à tous les fragments
print('=== bloc 5-45 (5.8.2 Créer les collections et insérer les données)')
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
print('=== bloc 5-46 (5.8.2 Créer les collections et insérer les données)')
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
print('=== bloc 5-47 (5.8.3 Interroger les données)')
db.activites.find({ _id: 3 },
  { nom: 1, horaires: 1,
    restantes: { $subtract: ["$capacite", "$inscrits"] } })
// { _id: 3, nom: 'Tennis de table',
//   horaires: [ { jour: 'lundi', debut: '18:00' },
//               { jour: 'jeudi', debut: '19:30' } ],
//   restantes: 11 }
print('=== bloc 5-48 (5.8.3 Interroger les données)')
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
print('=== bloc 5-49 (5.8.3 Interroger les données)')
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
FIN_JS
cd ..
