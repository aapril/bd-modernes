package org.etsmtl.ind500.models;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.apache.kafka.common.serialization.Serde;
import org.etsmtl.ind500.models.internal.Customer;
import org.etsmtl.ind500.models.internal.OrderItem;
import org.springframework.kafka.support.serializer.JsonSerde;

import java.util.ArrayList;
import java.util.List;

public class Order {

    @JsonIgnore
    public static Serde<Order> getSerde(){
        return new JsonSerde<>(Order.class);
    }

    @JsonProperty("uuid")
    private String uuid;

    @JsonProperty("date")
    private String date;

    @JsonProperty("status")
    private String status;

    @JsonProperty("customer")
    private Customer customer;

    @JsonProperty("items")
    private List<OrderItem> orderItems;

    public Order() {
        this.uuid = "";
        this.date = "";
        this.status = "";
        this.customer = null;
        this.orderItems = new ArrayList<>();
    }

    public String getUuid() {
        return uuid;
    }

    public void setUuid(String uuid) {
        this.uuid = uuid;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Customer getCustomer() {
        return customer;
    }

    public void setCustomer(Customer customer) {
        this.customer = customer;
    }

    public List<OrderItem> getItems() {
        return orderItems;
    }
}
