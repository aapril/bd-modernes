package org.etsmtl.ind500.models.internal;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.apache.kafka.common.serialization.Serde;
import org.springframework.kafka.support.serializer.JsonSerde;

public class Transporter {

    @JsonIgnore
    public static Serde<Transporter> getSerde(){
        return new JsonSerde<>(Transporter.class);
    }

    @JsonProperty("id")
    private String id;

    @JsonProperty("state")
    private String state;

    @JsonProperty("city")
    private String city;

    public Transporter(){
        this("","","");
    }

    public Transporter(String id, String state, String city){
        this.id = id;
        this.state = state;
        this.city = city;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getState() {
        return state;
    }

    public void setState(String state) {
        this.state = state;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }
}
