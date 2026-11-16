package org.etsmtl.ind500.models;

import com.fasterxml.jackson.annotation.*;
import org.apache.kafka.common.serialization.Serde;
import org.etsmtl.ind500.models.internal.ILocation;
import org.etsmtl.ind500.models.internal.Location;
import org.etsmtl.ind500.models.internal.Transporter;
import org.springframework.kafka.support.serializer.JsonSerde;

import java.io.Serializable;

public class TransporterLocation implements ILocation,Serializable {

    @JsonIgnore
    public static Serde<TransporterLocation> getSerde(){
        return new JsonSerde<>(TransporterLocation.class);
    }

    @JsonProperty("transporter")
    @JsonUnwrapped
    private Transporter transporter;

    @JsonProperty("location")
    private Location location;

    public  TransporterLocation() {
        this(new Transporter(),new Location());
    }

    public TransporterLocation( Transporter transporter, Location location) {
        this.location = location;
        this.transporter = transporter;
    }


    public Transporter getTransporter() { return transporter; }
    public Location getLocation() {
        return location;
    }

    @JsonIgnore
    @Override
    public double getLatitude() {
        return location.getLatitude();
    }
    @JsonIgnore
    @Override
    public double getLongitude() {
        return location.getLongitude();
    }


    public void setTransporter(Transporter transporter) {
        this.transporter = transporter;
    }


    public void setLocation(Location location) {
        this.location = location;
    }

    @JsonIgnore
    @Override
    public void setLatitude(double lat) {
        this.location.setLatitude(lat);
    }
    @JsonIgnore
    @Override
    public void setLongitude(double lon) {
        this.location.setLongitude(lon);
    }
}
