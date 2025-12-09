# Citizen Mobile App 🏛️

A comprehensive mobile application for citizens to report civic issues, track complaints, and engage with local governance. Built with React Native, Expo, and TypeScript with **AI-powered issue detection**.

## 📋 Table of Contents

- [Features](#features)
- [AI Integration](#ai-integration)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Development](#development)
- [Internationalization](#internationalization)
- [API Integration](#api-integration)
- [Screenshots](#screenshots)
- [Contributing](#contributing)

## ✨ Features

### Core Features
- **🔐 Authentication**
  - OTP-based phone number authentication
  - Secure token-based session management
  - Automatic session persistence

- **📝 Issue Reporting**
  - Camera integration with flash control for photo capture
  - Gallery image selection support
  - GPS location tracking
  - **🤖 AI-powered issue detection** (Pothole & Garbage)
  - Real-time confidence scores
  - Multiple issue categories (Roads, Water, Electricity, Sanitation, etc.)
  - Priority levels (Low, Medium, High, Urgent)
  - Timestamp display on reports

- **📊 Complaint Management**
  - Real-time complaint tracking
  - Status updates (Submitted, In Progress, Resolved, Rejected)
  - Complaint filtering and search
  - Detailed complaint view with timeline
  - Upvote system with one vote per user restriction
  - Display of report time on complaint cards

- **🗺️ Nearby Issues**
  - Interactive map showing issues within 5km radius
  - Map markers for each complaint
  - Small map preview for each issue in list view
  - Current location tracking
  - Issue count badge

- **🔔 Notifications**
  - Push notification support
  - Status update alerts
  - Nearby issue notifications

## 🤖 AI Integration

### YOLO-based Detection
This app integrates a **YOLOv11 model** trained to detect:
- 🕳️ **Potholes** - Road damage and potholes
- 🗑️ **Garbage** - Waste and litter accumulation

### Features
- **Automatic Category Detection**: AI analyzes captured images
- **Confidence Scores**: Visual progress bars showing detection certainty
- **Smart Fallback**: Works offline when AI backend unavailable
- **Quality Analysis**: Checks image brightness, blur, and resolution
- **Manual Override**: Users can always change AI suggestions

### Quick Start
```bash
# Start AI Backend
cd AI_model
pip install -r requirements.txt
python server.py

# In new terminal - Start React Native App
npm start
```

📖 **Full Documentation**: See [AI_INTEGRATION_GUIDE.md](AI_INTEGRATION_GUIDE.md) and [QUICKSTART.md](QUICKSTART.md)
  - In-app notification center

- **👤 Profile Management**
  - User profile with statistics
  - Language preferences
  - Notification settings
  - Account information management

- **🌐 Multi-language Support**
  - English
  - Hindi (हिंदी)
  - Marathi (मराठी)
  - Tamil (தமிழ்)
  - Telugu (తెలుగు)
  - Bengali (বাংলা)

- **🔗 Sharing**
  - Native share functionality for complaints
  - Deep linking support

## 🛠️ Tech Stack

### Core Technologies
- **React Native** - Cross-platform mobile development
- **Expo SDK 54** - Development platform and tooling
- **TypeScript** - Type-safe development
- **Expo Router** - File-based routing system

### Key Libraries
- **react-native-maps** (1.14.0) - Map integration
- **expo-camera** - Camera functionality
- **expo-location** - GPS and location services
- **expo-notifications** - Push notifications
- **expo-sharing** - Native share dialog
- **i18next & react-i18next** - Internationalization
- **@react-native-async-storage/async-storage** - Local data persistence

### Development Tools
- **ESLint** - Code linting
- **TypeScript** - Static type checking
- **Metro Bundler** - JavaScript bundler

## 🚀 Getting Started

### Prerequisites
- Node.js (v16 or higher)
- npm or yarn
- Expo CLI
- iOS Simulator (Mac only) or Android Emulator
- Expo Go app (for physical device testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ReportApp
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure Google Maps API**
   - Get API keys from [Google Cloud Console](https://console.cloud.google.com/)
   - Update `app.json` with your API keys:
     ```json
     "android": {
       "config": {
         "googleMaps": {
           "apiKey": "YOUR_ANDROID_API_KEY"
         }
       }
     },
     "ios": {
       "config": {
         "googleMapsApiKey": "YOUR_IOS_API_KEY"
       }
     }
     ```

4. **Start the development server**
   ```bash
   npx expo start -c
   ```

5. **Run on device/emulator**
   - Press `a` for Android emulator
   - Press `i` for iOS simulator
   - Scan QR code with Expo Go app for physical device

## 📁 Project Structure

```
ReportApp/
├── app/                          # App entry points and routing
│   ├── (auth)/                   # Authentication screens
│   │   ├── login.tsx
│   │   └── otp.tsx
│   ├── (tabs)/                   # Bottom tab navigation
│   │   ├── _layout.tsx
│   │   ├── index.tsx             # Home screen
│   │   ├── complaints.tsx        # My complaints
│   │   ├── nearby.tsx            # Nearby issues with map
│   │   ├── notifications.tsx     # Notifications
│   │   └── profile.tsx           # User profile
│   ├── complaint/                # Complaint detail screen
│   │   └── [id].tsx
│   ├── report-issue.tsx          # Issue reporting flow
│   ├── _layout.tsx               # Root layout
│   └── index.tsx                 # App entry
├── src/
│   ├── components/               # Reusable components
│   │   ├── ui/                   # UI components
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   └── CategoryCard.tsx
│   │   └── complaints/           # Complaint components
│   │       ├── ComplaintCard.tsx
│   │       ├── ComplaintList.tsx
│   │       └── StatusBadge.tsx
│   ├── screens/                  # Screen components
│   │   ├── auth/
│   │   ├── home/
│   │   ├── complaints/
│   │   ├── nearby/
│   │   ├── notifications/
│   │   ├── profile/
│   │   └── report/
│   ├── contexts/                 # React contexts
│   │   ├── AuthContext.tsx
│   │   └── ComplaintContext.tsx
│   ├── services/                 # API and services
│   │   ├── api.ts
│   │   ├── storage.ts
│   │   └── notifications.ts
│   ├── hooks/                    # Custom hooks
│   │   └── useLocation.ts
│   ├── utils/                    # Utility functions
│   │   └── validators.ts
│   ├── constants/                # Constants and theme
│   │   ├── theme.ts
│   │   └── categories.ts
│   ├── i18n/                     # Internationalization
│   │   ├── index.ts
│   │   ├── en.json
│   │   ├── hi.json
│   │   ├── mr.json
│   │   ├── ta.json
│   │   ├── te.json
│   │   └── bn.json
│   └── types/                    # TypeScript types
│       └── index.ts
├── assets/                       # Static assets
│   └── images/
├── app.json                      # Expo configuration
├── package.json
├── tsconfig.json
└── README.md
```

## ⚙️ Configuration

### app.json
Key configurations in `app.json`:
- App name, version, and slug
- Platform-specific settings (iOS, Android, Web)
- Google Maps API keys
- Permissions (Camera, Location, Notifications)
- Splash screen and icon

### Environment Variables
For production, use environment variables for sensitive data:
```bash
EXPO_PUBLIC_API_URL=https://api.example.com
EXPO_PUBLIC_GOOGLE_MAPS_KEY=your_key_here
```

## 💻 Development

### Running the App

**Clear cache and start:**
```bash
npx expo start -c
```

**Run on specific platform:**
```bash
npx expo start --android
npx expo start --ios
npx expo start --web
```

### Development Commands

**Type checking:**
```bash
npx tsc --noEmit
```

**Linting:**
```bash
npm run lint
```

**Format code:**
```bash
npm run format
```

### Platform-Specific Notes

**Web Platform:**
- `react-native-maps` shows a fallback placeholder on web
- Camera functionality requires native platform
- Some features are mobile-only

**iOS:**
- Requires Xcode for iOS Simulator
- Google Maps API key needed for maps

**Android:**
- Requires Android Studio and emulator
- Google Maps API key needed for maps

## 🌐 Internationalization

The app supports 6 languages using i18next:

### Adding a New Language

1. Create translation file: `src/i18n/[language-code].json`
2. Add translations following the existing structure
3. Register in `src/i18n/index.ts`:
   ```typescript
   import newLang from './newlang.json';
   
   resources: {
     // ... existing languages
     nl: { translation: newLang }, // Dutch example
   }
   ```

### Using Translations in Code

```typescript
import { useTranslation } from 'react-i18next';

function MyComponent() {
  const { t } = useTranslation();
  return <Text>{t('home.welcome')}</Text>;
}
```

### Changing Language

Users can change language from Profile screen, or programmatically:
```typescript
import i18n from '../i18n';
i18n.changeLanguage('hi'); // Switch to Hindi
```

## 🔌 API Integration

### Current Implementation
The app uses a mock API service (`src/services/api.ts`) with simulated data and delays. This allows development without a backend.

### Connecting to Real API

1. **Update API service:**
   ```typescript
   // src/services/api.ts
   const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'https://api.example.com';
   
   export const apiClient = {
     async get(endpoint: string) {
       const response = await fetch(`${API_BASE_URL}${endpoint}`, {
         headers: { 'Authorization': `Bearer ${token}` }
       });
       return response.json();
     },
     // ... other methods
   };
   ```

2. **Update authentication flow:**
   - Replace mock OTP verification
   - Implement real token management
   - Handle refresh tokens

3. **Update complaint operations:**
   - Connect create, update, delete operations
   - Implement real-time status updates
   - Add image upload to cloud storage

### API Endpoints (Expected)

```
POST   /auth/send-otp        - Send OTP to phone
POST   /auth/verify-otp      - Verify OTP and get token
GET    /complaints           - Get user's complaints
POST   /complaints           - Create new complaint
GET    /complaints/:id       - Get complaint details
PUT    /complaints/:id       - Update complaint
POST   /complaints/:id/upvote - Upvote complaint
GET    /complaints/nearby    - Get nearby complaints
GET    /notifications        - Get user notifications
GET    /profile              - Get user profile
PUT    /profile              - Update user profile
```

## 📸 Screenshots







## 🧪 Testing

### Manual Testing Checklist

- [✅] Login with OTP
- [✅] Report new issue with camera and location
- [✅] View and filter complaints
- [✅] View nearby issues on map
- [✅] Upvote a complaint (verify one vote limit)
- [✅] Share a complaint
- [ ] Change language
- [✅] Receive notifications
- [✅] Update profile

### Test Data

The mock API includes test complaints with various statuses and categories. Check `src/services/api.ts` for sample data.

## 🚢 Deployment

### Building for Production

**Android APK:**
```bash
eas build --platform android --profile production
```

**iOS:**
```bash
eas build --platform ios --profile production
```

### Prerequisites for EAS Build
1. Create Expo account
2. Install EAS CLI: `npm install -g eas-cli`
3. Configure `eas.json`
4. Set up credentials

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- [Expo](https://expo.dev) - Amazing development platform
- [React Native](https://reactnative.dev) - Cross-platform framework
- [react-native-maps](https://github.com/react-native-maps/react-native-maps) - Map integration

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Contact: [anujselokar7@gmail.com]
- Phone No.:[+917219399721]

## 🗺️ Roadmap

- [ ] Real-time chat with authorities
- [ ] AI-powered issue description suggestions
- [ ] Offline mode support
- [ ] Dark mode
- [ ] Issue analytics dashboard
- [ ] Community forum
- [ ] Gamification and rewards

---

**Built with ❤️ for better civic engagement**
