package org.etsmtl.ind500.models.internal;

import com.fasterxml.jackson.annotation.*;
import org.apache.kafka.common.serialization.Serde;
import org.springframework.kafka.support.serializer.JsonSerde;

public class OrderItem {

    @JsonIgnore
    public static Serde<OrderItem> getSerde(){
        return new JsonSerde<>(OrderItem.class);
    }

    @JsonProperty("qty")
    private int qty;

    @JsonProperty("product")
    private Product product;

    @JsonProperty("seller")
    private Seller seller;

    public OrderItem() {
        this(0, new Product(), new Seller());
    }

    public OrderItem(int qty, Product product, Seller seller) {
        this.qty = qty;
        this.product = product;
        this.seller = seller;
    }

    public int getQty() {
        return qty;
    }

    public void setQty(int qty) {
        this.qty = qty;
    }

    public Product getProduct() {
        return product;
    }

    public void setProduct(Product product) {
        this.product = product;
    }

    public Seller getSeller() {
        return seller;
    }

    public void setSeller(Seller seller) {
        this.seller = seller;
    }
}

