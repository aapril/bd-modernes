package org.etsmtl.ind500.utils.internal;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.streams.errors.ErrorHandlerContext;
import org.apache.kafka.streams.errors.ProductionExceptionHandler;

import java.util.Map;
import java.util.logging.Logger;

/*
* Utilisé par EtsKafkaStreamsConfig.
* */

public class EtsProductionExceptionHandler implements ProductionExceptionHandler {
    Logger log = Logger.getLogger(EtsProductionExceptionHandler.class.getName());
    @Override
    public ProductionExceptionHandlerResponse handle(final ErrorHandlerContext context,
                                                     final ProducerRecord<byte[], byte[]> record,
                                                     final Exception exception) {
        log.warning(exception.getMessage());
        return ProductionExceptionHandlerResponse.CONTINUE;
    }

    @Override
    public ProductionExceptionHandlerResponse handleSerializationException(final ErrorHandlerContext context,
                                                                           final ProducerRecord record,
                                                                           final Exception exception,
                                                                           final SerializationExceptionOrigin origin) {
        log.warning(exception.getMessage());
        return ProductionExceptionHandlerResponse.CONTINUE;
    }

    @Override
    public void configure(Map<String, ?> configs) {}
}
