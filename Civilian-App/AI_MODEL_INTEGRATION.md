# AI Model Integration

## Overview
The app now integrates a TensorFlow.js model trained to detect **potholes/road damage** and **garbage** from images.

## Model Details
- **Type**: MobileNet v2 (Teachable Machine)
- **Input**: 224x224 RGB images
- **Output**: 2 classes
  - `road_damage` → Maps to `pothole` category
  - `garbage` → Maps to `garbage` category
- **Location**: `assets/model/`

## How It Works

### 1. Model Initialization
The model is loaded when the app starts in `app/_layout.tsx`:
```typescript
await aiService.initialize();
```

### 2. Image Prediction
When a user captures/selects an image in `ReportFormScreen`:
```typescript
const result = await aiService.detectCategory(imageUri);
// Returns: { category, confidence, suggestions }
```

### 3. Preprocessing Pipeline
1. Image resized to 224x224 using `expo-image-manipulator`
2. Converted to base64
3. Decoded to tensor using `decodeJpeg`
4. Normalized to [-1, 1] range (MobileNet preprocessing)
5. Prediction run through model
6. Result mapped to app categories

## Features

### ✅ Automatic Category Detection
- AI analyzes the captured image
- Suggests the most likely category
- Shows confidence score

### ✅ Fallback Mode
- If model fails to load or predict
- Falls back to random selection
- App continues to work normally

### ✅ Smart Suggestions
- Based on prediction, suggests related categories
- For potholes: suggests road damage, footpath, drainage
- For garbage: suggests sewage, drainage, public toilet

## Usage

### For Users
1. Take a photo of the issue
2. AI automatically detects the category
3. Review and adjust if needed
4. Add description and submit

### For Developers

**Test the model:**
```typescript
import { aiService } from './src/services/aiService';

// Initialize (if not already done)
await aiService.initialize();

// Predict
const result = await aiService.detectCategory(imageUri);
console.log(result);
// Output: { category: 'pothole', confidence: 0.89, suggestions: [...] }
```

## Model Training

The current model was trained using Google's Teachable Machine with:
- Training images of potholes and road damage
- Training images of garbage and waste

### To retrain or update:
1. Go to https://teachablemachine.withgoogle.com/train/image
2. Upload new training images
3. Train the model
4. Export as "TensorFlow.js" format
5. Replace files in `assets/model/`

## Performance

- **Model Size**: ~4MB (weights.bin)
- **Inference Time**: ~1-2 seconds
- **Accuracy**: Depends on training data quality
- **Platform**: Works on iOS and Android

## Troubleshooting

### Model not loading
- Check console logs for initialization errors
- Ensure model files are in `assets/model/`
- Verify TensorFlow.js dependencies are installed

### Low accuracy
- Model is trained on limited data
- Consider retraining with more diverse images
- Add more classes for better categorization

### Performance issues
- Model runs on device (no internet needed)
- First prediction may be slower (model loading)
- Subsequent predictions are faster

## Future Improvements

1. **More Categories**: Train model to detect all 15 issue types
2. **Better Accuracy**: Use larger training dataset
3. **Multi-label**: Detect multiple issues in one image
4. **Quality Check**: Detect blurry or low-quality images
5. **Severity Detection**: AI-based severity estimation

## Dependencies

```json
{
  "@tensorflow/tfjs": "^4.x",
  "@tensorflow/tfjs-react-native": "^1.x",
  "expo-gl": "^14.x",
  "expo-gl-cpp": "^1.x",
  "expo-image-manipulator": "^12.x"
}
```

## Notes

- Model runs completely offline (no API calls)
- Privacy-friendly (images stay on device)
- Fallback ensures app works even if model fails
- Compatible with Expo managed workflow
