package org.etsmtl.ind500.models.internal;

import com.fasterxml.jackson.annotation.*;
import org.apache.kafka.common.serialization.Serde;
import org.springframework.kafka.support.serializer.JsonSerde;

public class Customer implements ILocation{
    @JsonIgnore
    public static Serde<Customer> getSerde(){
        return new JsonSerde<>(Customer.class);
    }

    @JsonProperty("uniqueId")
    private String uniqueId;

    @JsonProperty("firstname")
    private String firstname;

    @JsonProperty("lastname")
    private String lastname;

    @JsonProperty("phone")
    private String phone;

    @JsonProperty("address")
    private String address;

    @JsonProperty("zipcode")
    private String zipCode;

    @JsonProperty("city")
    private String city;

    @JsonProperty("state")
    private String state;

    @JsonProperty("location")
    private Location location;

    public Customer(){
        this("","","","","","","","",0,0);
    }

    public Customer(String uniqueId,
                    String firstname,
                    String lastname,
                    String phone,
                    String address,
                    String zipCode,
                    String city,
                    String state,
                    Location location){
        this.uniqueId = uniqueId;
        this.firstname = firstname;
        this.lastname = lastname;
        this.phone = phone;
        this.address = address;
        this.zipCode = zipCode;
        this.city = city;
        this.state = state;
        this.location = location;
    }

    public Customer(String uniqueId, String firstname, String lastname, String phone, String address, String zipCode, String city, String state, double lat, double lon){
        this(uniqueId,firstname,lastname,phone,address,zipCode,city,state, new Location(lat,lon));
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

    public String getZipCode() {
        return zipCode;
    }
    public void setZipCode(String zipCode) {
        this.zipCode = zipCode;
    }

    public String getAddress() {
        return address;
    }
    public void setAddress(String address) {
        this.address = address;
    }

    public String getPhone() { return phone; }
    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getLastname() {
        return lastname;
    }
    public void setLastname(String lastname) {
        this.lastname = lastname;
    }

    public String getFirstname() {
        return firstname;
    }
    public void setFirstname(String firstname) {
        this.firstname = firstname;
    }

    public String getUniqueId() {
        return uniqueId;
    }
    public void setUniqueId(String uniqueId) {
        this.uniqueId = uniqueId;
    }


    @Override
    @JsonIgnore
    public double getLatitude() {
        return location.getLatitude();
    }

    @Override
    @JsonIgnore
    public double getLongitude() {
        return location.getLongitude();
    }

    public Location getLocation() {
        return location;
    }

    @Override
    @JsonIgnore
    public void setLatitude(double lat) {
        this.location.setLatitude(lat);
    }

    @Override
    @JsonIgnore
    public void setLongitude(double lon) {
        this.location.setLongitude(lon);
    }

    public void setLocation(Location location) {
        this.location = location;
    }
}
