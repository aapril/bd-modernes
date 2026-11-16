package org.etsmtl.ind500.models.internal;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.apache.kafka.common.serialization.Serde;
import org.springframework.kafka.support.serializer.JsonSerde;

public class GenericReview {

    @JsonIgnore
    public static Serde<GenericReview> getSerde(){
        return new JsonSerde<>(GenericReview.class);
    }

    @JsonProperty("title")
    private String title;

    @JsonProperty("description")
    private String description;

    @JsonProperty("score")
    private int score;

    public GenericReview() {
        this("","",3);
    }

    public GenericReview(String title, String description, int score) {
        this.title = title;
        this.description = description;
        this.score = score;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public int getScore() {
        return score;
    }

    public void setScore(int score) {
        this.score = score;
    }
}
