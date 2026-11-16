package org.etsmtl.ind500.models.internal;

import com.fasterxml.jackson.annotation.*;
import org.apache.kafka.common.serialization.Serde;
import org.springframework.kafka.support.serializer.JsonSerde;

public class Seller implements ILocation{

    @JsonIgnore
    public static Serde<Seller> getSerde(){
        return new JsonSerde<>(Seller.class);
    }

    @JsonProperty("uuid")
    private String uuid;

    @JsonProperty("location")
    private Location location;

    public Seller() {
        this("",0,0);
    }

    public Seller(String uuid, Location location) {
        this.location = location;
        this.uuid = uuid;
    }

    public Seller(String uuid,double lat, double lon) {
        this(uuid,new Location(lat,lon));
    }

    public String getUuid() {
        return uuid;
    }
    public void setUuid(String uuid) {
        this.uuid = uuid;
    }

    @JsonIgnore
    public double getLatitude() {
        return location.getLatitude();
    }
    @JsonIgnore
    public double getLongitude() {
        return location.getLongitude();
    }

    public Location getLocation() {
        return location;
    }

    @JsonIgnore
    public void setLatitude(double lat) { this.location.setLatitude(lat); }
    @JsonIgnore
    public void setLongitude(double lon) {
        this.location.setLongitude(lon);
    }

    public void setLocation(Location location) {
        this.location = location;
    }
}
