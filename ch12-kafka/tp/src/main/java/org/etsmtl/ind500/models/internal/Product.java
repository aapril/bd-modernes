package org.etsmtl.ind500.models.internal;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.apache.kafka.common.serialization.Serde;
import org.springframework.kafka.support.serializer.JsonSerde;

public class Product {

    @JsonIgnore
    public static Serde<Product> getSerde(){
        return new JsonSerde<>(Product.class);
    }

    @JsonProperty("category")
    private String category;

    @JsonProperty("name")
    private String name;
    @JsonProperty("description")
    private String description;

    @JsonProperty("weight")
    private double weight;

    @JsonProperty("width")
    private double width;
    @JsonProperty("height")
    private double height;
    @JsonProperty("depth")
    private double depth;

    @JsonProperty("price")
    private double price; //Brazilian Reais

    public Product() {
        this("","","",0,0,0,0,0);
    }

    public Product(String category,
                   String name,
                   String description,
                   double weight,
                   double width,
                   double height,
                   double depth,
                   double price) {
        this.category = category;
        this.name = name;
        this.description = description;
        this.weight = weight;
        this.width = width;
        this.height = height;
        this.depth = depth;
        this.price = price;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Double getWeight() {
        return weight;
    }

    public void setWeight(Double weight) {
        this.weight = weight;
    }

    public Double getWidth() {
        return width;
    }

    public void setWidth(Double width) {
        this.width = width;
    }

    public Double getHeight() {
        return height;
    }

    public void setHeight(Double height) {
        this.height = height;
    }

    public Double getDepth() {
        return depth;
    }

    public void setDepth(Double depth) {
        this.depth = depth;
    }

    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }
}
