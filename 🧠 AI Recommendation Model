import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.metrics.pairwise import cosine_similarity

class PropertyRecommendationModel:
    def __init__(self, properties_df):
        self.properties_df = properties_df
        self.scaler = StandardScaler()
        
    def preprocess_features(self):
        features = [
            'price', 'area_sqm', 'bedrooms', 
            'walkability_score', 'safety_index'
        ]
        scaled_features = self.scaler.fit_transform(
            self.properties_df[features]
        )
        return scaled_features
    
    def calculate_similarity(self, user_preferences):
        scaled_features = self.preprocess_features()
        user_vector = np.array(list(user_preferences.values())).reshape(1, -1)
        
        similarities = cosine_similarity(user_vector, scaled_features)[0]
        return similarities
    
    def recommend_properties(self, user_preferences, top_n=5):
        similarities = self.calculate_similarity(user_preferences)
        top_indices = similarities.argsort()[-top_n:][::-1]
        
        return self.properties_df.iloc[top_indices]
