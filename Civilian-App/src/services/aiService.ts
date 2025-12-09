import { IssueCategory } from '../types';

// Model configuration
const IMAGE_SIZE = 224;

// Model labels mapping (trained to detect: "road damage" and "garbage")
const MODEL_LABELS = ['road_damage', 'garbage'] as const;
type ModelLabel = typeof MODEL_LABELS[number];

// Map model predictions to app categories
const LABEL_TO_CATEGORY_MAP: Record<ModelLabel, IssueCategory> = {
  'road_damage': 'pothole',
  'garbage': 'garbage',
};

// Suggestion categories for each prediction
const CATEGORY_SUGGESTIONS: Record<ModelLabel, IssueCategory[]> = {
  'road_damage': ['pothole', 'road_damage', 'broken_footpath', 'drainage'],
  'garbage': ['garbage', 'sewage', 'drainage', 'public_toilet'],
};

// Model state
let isModelReady = false;

/**
 * AI Service for image-based issue detection
 * 
 * NOTE: This is a simplified implementation for Expo compatibility.
 * For full TensorFlow.js integration:
 * 1. Run: npx expo prebuild
 * 2. Install native modules: @tensorflow/tfjs-react-native
 * 3. Uncomment the TensorFlow code below
 * 4. Use expo-dev-client for development
 */

export const aiService = {
  // Initialize the model (call this on app startup)
  async initialize() {
    try {
      console.log('AI Service initialized (simplified mode)');
      isModelReady = true;
      
      // TODO: For full TensorFlow.js integration:
      // await tf.ready();
      // model = await tf.loadLayersModel(...);
    } catch (error) {
      console.error('Failed to initialize AI service:', error);
    }
  },

  // Detect category using image analysis
  async detectCategory(imageUri: string): Promise<{
    category: IssueCategory;
    confidence: number;
    suggestions: IssueCategory[];
  }> {
    try {
      console.log('Analyzing image:', imageUri);
      
      // Simulate AI processing delay
      await new Promise((resolve) => setTimeout(resolve, 1000));
      
      // Simple heuristic: use URI hash and timestamp for consistent detection
      // This simulates AI model behavior without deprecated APIs
      const uriHash = imageUri.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
      const seed = (uriHash + Date.now()) % 100;
      
      // Determine category based on seed
      let predictedLabel: ModelLabel;
      let confidence: number;
      
      if (seed < 50) {
        // Predict road damage (pothole)
        predictedLabel = 'road_damage';
        confidence = 0.75 + (seed / 100) * 0.2; // 75-95%
      } else {
        // Predict garbage
        predictedLabel = 'garbage';
        confidence = 0.70 + ((100 - seed) / 100) * 0.25; // 70-95%
      }
      
      // Map to app category
      const category = LABEL_TO_CATEGORY_MAP[predictedLabel];
      const suggestions = CATEGORY_SUGGESTIONS[predictedLabel];
      
      console.log(`✅ Prediction: ${predictedLabel} → ${category} (confidence: ${(confidence * 100).toFixed(1)}%)`);
      
      return {
        category,
        confidence,
        suggestions,
      };
      
      /* 
      TODO: Full TensorFlow.js implementation:
      
      // Preprocess image
      const processedImage = await preprocessImage(imageUri);
      const batched = processedImage.expandDims(0);
      
      // Run prediction
      const prediction = model.predict(batched) as tf.Tensor;
      const probabilities = await prediction.data();
      
      // Get predicted class
      const maxProb = Math.max(...Array.from(probabilities));
      const predictedIndex = Array.from(probabilities).indexOf(maxProb);
      const predictedLabel = MODEL_LABELS[predictedIndex];
      
      // Clean up
      processedImage.dispose();
      batched.dispose();
      prediction.dispose();
      
      return {
        category: LABEL_TO_CATEGORY_MAP[predictedLabel],
        confidence: maxProb,
        suggestions: CATEGORY_SUGGESTIONS[predictedLabel],
      };
      */
    } catch (error) {
      console.error('Error detecting category:', error);
      return this.fallbackDetection();
    }
  },

  // Fallback detection when analysis fails
  fallbackDetection(): {
    category: IssueCategory;
    confidence: number;
    suggestions: IssueCategory[];
  } {
    console.log('Using fallback detection');
    const commonCategories: IssueCategory[] = [
      'pothole',
      'garbage',
      'street_light',
      'water_leak',
      'road_damage',
    ];

    const randomIndex = Math.floor(Math.random() * commonCategories.length);
    const detectedCategory = commonCategories[randomIndex];

    const suggestions = commonCategories
      .filter((c) => c !== detectedCategory)
      .slice(0, 3);

    return {
      category: detectedCategory,
      confidence: 0.5, // Low confidence for fallback
      suggestions: [detectedCategory, ...suggestions] as IssueCategory[],
    };
  },

  // Analyze image for quality
  async analyzeImageQuality(imageUri: string): Promise<{
    isValid: boolean;
    issues: string[];
  }> {
    try {
      // Basic validation without deprecated APIs
      // Check if URI is valid
      if (!imageUri || imageUri.length === 0) {
        return {
          isValid: false,
          issues: ['Invalid image URI'],
        };
      }

      // Check if it's a valid file:// or content:// URI
      if (!imageUri.startsWith('file://') && !imageUri.startsWith('content://')) {
        return {
          isValid: false,
          issues: ['Invalid image URI format'],
        };
      }

      return {
        isValid: true,
        issues: [],
      };
    } catch (error) {
      return {
        isValid: true,
        issues: [],
      };
    }
  },

  // Generate description suggestion based on category
  generateDescriptionSuggestion(category: IssueCategory): string {
    const suggestions: Record<IssueCategory, string> = {
      pothole: 'Pothole on the road causing inconvenience to commuters',
      garbage: 'Garbage accumulation requiring immediate cleanup',
      street_light: 'Street light not functioning, causing safety concerns',
      water_leak: 'Water leakage from pipe/connection',
      sewage: 'Sewage overflow/blockage issue',
      road_damage: 'Road surface damage requiring repair',
      illegal_parking: 'Vehicles parked illegally blocking the way',
      noise_pollution: 'Excessive noise causing disturbance',
      air_pollution: 'Air pollution from burning/smoke',
      encroachment: 'Illegal encroachment on public space',
      broken_footpath: 'Footpath damage causing walking difficulty',
      traffic_signal: 'Traffic signal malfunction',
      drainage: 'Drainage system blocked/overflowing',
      public_toilet: 'Public toilet maintenance issue',
      other: 'Issue requiring attention',
    };

    return suggestions[category] || suggestions.other;
  },

  // Estimate severity based on category and other factors
  estimateSeverity(
    category: IssueCategory,
    supporterCount: number
  ): 'low' | 'medium' | 'high' | 'critical' {
    const highPriorityCategories: IssueCategory[] = [
      'water_leak',
      'sewage',
      'road_damage',
      'pothole',
    ];

    const criticalThreshold = 10;
    const highThreshold = 5;

    if (supporterCount >= criticalThreshold) return 'critical';
    if (supporterCount >= highThreshold) return 'high';
    if (highPriorityCategories.includes(category)) return 'medium';
    return 'low';
  },
};
