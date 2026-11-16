package org.etsmtl.ind500.models;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonUnwrapped;
import org.apache.kafka.common.serialization.Serde;
import org.etsmtl.ind500.models.internal.GenericReview;
import org.springframework.kafka.support.serializer.JsonSerde;

public class OrderReview {

    @JsonIgnore
    public static Serde<OrderReview> getSerde(){
        return new JsonSerde<>(OrderReview.class);
    }

    @JsonProperty("reviewId")
    private String reviewId;

    @JsonProperty("orderId")
    private String orderId;

    @JsonUnwrapped
    private GenericReview review;

    public OrderReview() {
        this("","",new GenericReview());
    }

    public OrderReview(String reviewId, String orderId, GenericReview review) {
        this.reviewId = reviewId;
        this.orderId = orderId;
        this.review = review;
    }

    public OrderReview(String reviewId, String orderId, String title, String description, int score) {
        this(reviewId, orderId, new GenericReview(title, description, score));
    }

    public String getReviewId() {
        return reviewId;
    }

    public void setReviewId(String reviewId) {
        this.reviewId = reviewId;
    }

    public String getOrderId() {
        return orderId;
    }

    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }

    public GenericReview getReview() {
        return review;
    }

    public void setReview(GenericReview review) {
        this.review = review;
    }
}
