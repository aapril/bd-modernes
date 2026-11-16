import hashlib, json, time, plyvel

db = plyvel.DB("/tmp/registre_vehicules", create_if_missing=True)

def empreinte(tx: dict) -> str:
    texte = json.dumps(tx, sort_keys=True).encode()
    return hashlib.sha256(texte).hexdigest()

def dernier():
    for cle, val in db.iterator(prefix=b"tx:", reverse=True):
        return json.loads(val)
    return None

def ajouter(vin: str, proprietaire: str) -> dict:
    prec = dernier()
    tx = {"no": (prec["no"] + 1) if prec else 1,
          "vin": vin, "proprietaire": proprietaire,
          "moment": time.time(),
          "precedent": prec["hash"] if prec else "0" * 64}
    tx["hash"] = empreinte(tx)
    with db.write_batch() as lot:
        lot.put(f"tx:{tx['no']:09d}".encode(),
                json.dumps(tx).encode())
        lot.put(f"vin:{vin}".encode(), json.dumps(tx).encode())
    return tx
def verifier() -> bool:
    attendu = "0" * 64
    for cle, val in db.iterator(prefix=b"tx:"):
        tx = json.loads(val)
        h = tx.pop("hash")
        if tx["precedent"] != attendu or empreinte(tx) != h:
            print("Altération détectée à la transaction", tx["no"])
            return False
        attendu = h
    return True

ajouter("5YJ3E1EA7JF000001", "Julie Tremblay")
ajouter("5YJ3E1EA7JF000001", "Minh Nguyen")
print(verifier())          # True
# falsification
tx=json.loads(db.get(b"tx:000000001")); tx["proprietaire"]="Fraudeur"; db.put(b"tx:000000001", json.dumps(tx).encode())
print(verifier())
