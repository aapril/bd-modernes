package org.etsmtl.ind500.models.internal;

import java.io.Serializable;

import com.fasterxml.jackson.annotation.*;
import org.apache.kafka.common.serialization.Serde;
import org.springframework.kafka.support.serializer.JsonSerde;

public class Location implements ILocation,Serializable {

    @JsonIgnore
    public static Serde<Location> getSerde(){
        return new JsonSerde<>(Location.class);
    }

    @JsonProperty("latitude")
    private double latitude;

    @JsonProperty("longitude")
    private double longitude;

    public Location() {
        this(0,0);
    }

    public Location(double latitude, double longitude) {
        this.latitude = latitude;
        this.longitude = longitude;
    }

    public double getLatitude() {
        return latitude;
    }
    public void setLatitude(double lat) {
        this.latitude = lat;
    }

    public double getLongitude() {
        return longitude;
    }
    public void setLongitude(double lon) {
        this.longitude = lon;
    }
}
