CREATE FUNCTION vérifier_âge_client() RETURNS trigger AS $$
BEGIN
  IF (SELECT date_naissance IS NULL
             OR age(date_naissance) < interval '18 years'
      FROM client WHERE id_client = NEW.id_client) THEN
    RAISE EXCEPTION
      'Le client % doit avoir au moins 18 ans',
      NEW.id_client;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_âge_client
BEFORE INSERT OR UPDATE ON carte_crédit
FOR EACH ROW EXECUTE FUNCTION vérifier_âge_client();
