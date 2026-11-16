package org.etsmtl.ind500.utils.internal;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.errors.LogAndContinueExceptionHandler;
import org.apache.kafka.streams.errors.LogAndContinueProcessingExceptionHandler;
import org.apache.kafka.streams.state.BuiltInDslStoreSuppliers;
import org.apache.kafka.streams.state.DslStoreSuppliers;
import org.etsmtl.ind500.configs.Config;

import java.util.Properties;


/*
* Permets de configurer les streams Kafka.
* Ces configurations de base permettent d'afficher tout les erreurs de traitement et permets l'utilisation des Stores sur windows
*
* Conseil: Si vous voulez différentes configurations veuillez en ajouter apres l'appel à ces fonctions.
* */
public class EtsKafkaStreamsConfigs {
    public static Properties getStreamsConfigs(String applicationId, String clientId, Class<?> defaultKeySerde,Class<?> defaultValueSerde,boolean fromStart) {
        Properties props = new Properties();
        DslStoreSuppliers storesInMemory = new BuiltInDslStoreSuppliers.InMemoryDslStoreSuppliers();

        props.put(StreamsConfig.APPLICATION_ID_CONFIG, applicationId);
        props.put(StreamsConfig.CLIENT_ID_CONFIG, clientId);
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, Config.HOST);
        props.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, defaultKeySerde);
        props.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, defaultValueSerde);
        //props.put(StreamsConfig.COMMIT_INTERVAL_MS_CONFIG, 1000);
        props.put(StreamsConfig.DESERIALIZATION_EXCEPTION_HANDLER_CLASS_CONFIG, LogAndContinueExceptionHandler.class.getName());
        props.put(StreamsConfig.PROCESSING_EXCEPTION_HANDLER_CLASS_CONFIG, LogAndContinueProcessingExceptionHandler.class.getName());
        props.put(StreamsConfig.PRODUCTION_EXCEPTION_HANDLER_CLASS_CONFIG, EtsProductionExceptionHandler.class.getName());
        props.put(StreamsConfig.DSL_STORE_SUPPLIERS_CLASS_CONFIG,storesInMemory.getClass());

        if(fromStart)
            props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

        return props;
    }

    public static Properties getStreamsConfigs(String applicationId, String clientId) {
        return getStreamsConfigs(applicationId, clientId, Serdes.String().getClass(), Serdes.String().getClass(), false);
    }

    public static Properties getStreamsConfigs(String applicationId, String clientId, Class<?> defaultKeySerde,Class<?> defaultValueSerde) {
        return getStreamsConfigs(applicationId, clientId, defaultKeySerde, defaultValueSerde, false);
    }

    public static Properties getStreamsConfigs(String applicationId, String clientId, boolean fromStart) {
        return getStreamsConfigs(applicationId,clientId,Serdes.String().getClass(),Serdes.String().getClass(),fromStart);
    }

    /*
    * Je serais surpris que vous en avez de besoin
    * */
    public static Properties overrideHost(Properties props, String host) {
        props.remove(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG);
        props.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG,host);

        return props;
    }


    private EtsKafkaStreamsConfigs() {}
}
