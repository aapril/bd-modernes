package org.etsmtl.ind500.configs;

public class Config {
    public static final String HOST = "localhost:9092";

    /****************************************************************************************************************
     * Canaux à lire
     ****************************************************************************************************************/

    /*********************************************
     * Clé: UUID du livreur
     * Valeur: Models.TransporterLocation (en JSON)
     **********************************************/
    public static final String TRANSPORTER_LOCATION_TOPIC = "transporterLocation";

    /*********************************************
     * Clé: UUID de la commande
     * Valeur: Models.Order (en JSON)
     **********************************************/
    public static final String NEW_ORDER_TOPIC = "newOrder";

    /*********************************************
     * Clé: UUID de la commande
     * Valeur: Models.OrderReview (en JSON)
     **********************************************/
    public static final String ORDER_REVIEW_TOPIC = "orderReview";


    /***
     * Clé: UUID de la commande
     * Valeur:
     * {
     *   orderId:String, //UUID
     *   transporterId:String, //UUID
     *   quotePrice:double //soumission pour livrer la commande
     * }
     **/
    public static final String SHIPPING_QUOTE_RESPONSE_TOPIC = "shippingQuoteResponse";

    /****************************************************************************************************************
     * Canaux à répondre / utilisé
     ****************************************************************************************************************/

    /*********************************************
     * Clé: SellerId
     * Valeur: moyenne des scores des revues (double)
     *********************************************/
    public static final String SELLER_REVIEW_SCORE_STATS_TOPIC = "sellerReviewScoreStats";

    /*********************************************
     * Clé: UUID de la commande
     * Valeur:
     * {
     *   orderId: String, //order's uuid (32 hex char)
     *   transporterId: String, //transporter's uuid (32 hex char)
     *   deliverySpecs: {
     *     totalWeight: double, //Total de tout les poids des produits de la commande
     *     maxWidth: double,  //Largeur maximum de tous les produits de la commande
     *     maxHeight: double, //Hauteur maximum de tous les produits de la commande
     *     maxDepth: double //Profondeur maximum de tous les produits de la commande
     *   }
     * }
     *********************************************/
    public static final String SHIPPING_QUOTE_REQUEST_TOPIC = "shippingQuoteRequest";

    /*********************************************
     * Clé: UUID de la commande
     * Valeur:
     * {
     *   orderId: String, //order's uuid (32 hex char),
     *   transporterId: String, //transporter's uuid (32 hex char),
     *   quotePrice: double,
     *   quoteStatus: String //"ACCEPT"|"REJECT"
     * }
     *********************************************/
    public static final String SHIPPING_QUOTE_CONFIRMATION_TOPIC = "shippingQuoteConfirmation";
}
