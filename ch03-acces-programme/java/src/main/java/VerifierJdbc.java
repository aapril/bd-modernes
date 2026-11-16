import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

/** Chapitre 3 : vérifie l'accès JDBC à la base club du chapitre 2. */
public class VerifierJdbc {
    public static void main(String[] args) throws Exception {
        String url = "jdbc:postgresql://localhost:5432/club";
        try (Connection con = DriverManager.getConnection(url, "postgres", "MotDePasse123");
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery("SELECT count(*) FROM membres")) {
            rs.next();
            System.out.println("Connexion JDBC réussie, membres : " + rs.getInt(1));
        }
    }
}
