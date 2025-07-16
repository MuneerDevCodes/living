# Carbon Footprint Integration Documentation

## Overview

This document describes the comprehensive carbon footprint tracking system integrated into the Living app, inspired by the Carbos project. The system provides users with detailed carbon footprint tracking, analytics, goal setting, and social features to encourage sustainable living.

## Features

### 1. Comprehensive Carbon Tracking
- **Multi-category tracking**: Transportation, Energy, Food, Waste, Water, Digital
- **Scientific emission factors**: Based on EPA, FAO, and other authoritative sources
- **Regional variations**: Different emission factors for US, EU, and Asia
- **Detailed activity logging**: Support for 20+ activity types with specific emission factors

### 2. Advanced Analytics
- **Real-time calculations**: Automatic carbon impact calculations
- **Trend analysis**: Weekly, monthly, and yearly trends
- **Category breakdown**: Visual representation of footprint by category
- **Progress tracking**: Reduction percentages and goal progress

### 3. Goal Setting & Management
- **Personalized goals**: Set custom carbon reduction targets
- **Progress tracking**: Visual progress indicators
- **Goal categories**: Transportation, Energy, Food, etc.
- **Achievement system**: Gamification to encourage engagement

### 4. Social Features
- **Leaderboard**: Compare with other users
- **Achievements**: Unlock badges for milestones
- **Challenges**: Participate in community challenges
- **Insights**: Personalized recommendations and insights

### 5. Educational Content
- **Tips and recommendations**: Personalized suggestions for reduction
- **Educational resources**: Information about carbon impact
- **Best practices**: Sustainable living guidance

## Architecture

### Models

#### CarbonFootprintEntry
```dart
class CarbonFootprintEntry {
  final String key;
  final String userId;
  final String activityType;
  final double value;
  final String unit;
  final double carbonImpact;
  final DateTime date;
  final String? notes;
  final String category;
  final String subcategory;
  final double emissionFactor;
  final String location;
  final bool isVerified;
}
```

#### CarbonGoal
```dart
class CarbonGoal {
  final String key;
  final String userId;
  final String title;
  final String description;
  final double targetValue;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final bool isActive;
  final double currentProgress;
  final String status;
}
```

#### CarbonAnalytics
```dart
class CarbonAnalytics {
  final double totalFootprint;
  final double weeklyAverage;
  final double monthlyAverage;
  final double yearlyAverage;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> weeklyTrend;
  final Map<String, double> monthlyTrend;
  final double reductionPercentage;
  final double targetFootprint;
  final String rank;
  final int totalEntries;
}
```

### Services

#### CarbonFootprintDAO
- Database operations for carbon footprint entries
- Goal management
- Analytics calculations
- Comprehensive emission factors

#### CarbonCalculatorService
- Advanced carbon calculations
- Regional emission factors
- Transportation, energy, food, waste calculations
- Digital footprint calculations

#### CarbonInsightsService
- Achievement system
- Personalized recommendations
- Social features
- Leaderboard management

## Emission Factors

### Transportation
- **Car (Gasoline)**: 0.404 kg CO2/km
- **Car (Electric)**: 0.092 kg CO2/km
- **Bus**: 0.105 kg CO2/km
- **Train**: 0.041 kg CO2/km
- **Air Travel**: 0.255 kg CO2/km
- **Walking/Cycling**: 0.0 kg CO2/km

### Energy
- **Electricity**: 0.92 kg CO2/kWh
- **Natural Gas**: 2.02 kg CO2/m³
- **Heating Oil**: 2.68 kg CO2/L
- **Solar/Wind**: 0.0 kg CO2/kWh

### Food
- **Beef**: 13.3 kg CO2/kg
- **Pork**: 4.6 kg CO2/kg
- **Chicken**: 2.9 kg CO2/kg
- **Dairy**: 1.4 kg CO2/kg
- **Vegetables**: 0.2 kg CO2/kg
- **Fruits**: 0.3 kg CO2/kg
- **Grains**: 0.5 kg CO2/kg

### Waste
- **General Waste**: 0.5 kg CO2/kg
- **Recycled**: -0.3 kg CO2/kg (carbon saved)
- **Composted**: -0.2 kg CO2/kg (carbon saved)

### Water
- **Hot Water**: 0.298 kg CO2/L
- **Bottled Water**: 0.298 kg CO2/L
- **Cold Water**: 0.001 kg CO2/L

### Digital
- **Internet Usage**: 0.0001 kg CO2/GB
- **Video Streaming**: 0.0004 kg CO2/hour

## Pages

### 1. Carbon Footprint Page (`/carbon-footprint`)
- **Overview Tab**: Current footprint, rank, category breakdown, tips
- **Log Activity Tab**: Comprehensive activity logging with categories
- **Analytics Tab**: Detailed analytics and trends
- **Goals Tab**: Goal management and progress tracking

### 2. Carbon History Page (`/carbon-history`)
- **Filtering**: By category, time range, custom dates
- **Detailed entries**: Full activity details with notes and location
- **Summary statistics**: Total entries, footprint, averages
- **Export capabilities**: Data export for analysis

### 3. Carbon Insights Page (`/carbon-insights`)
- **Overview Tab**: User stats, level progress, insights, challenges
- **Achievements Tab**: Achievement system with progress tracking
- **Recommendations Tab**: Personalized reduction suggestions
- **Social Tab**: Leaderboard and social statistics

## Usage Guide

### Logging Activities

1. **Navigate to Carbon Footprint page**
2. **Select "Log Activity" tab**
3. **Choose category** (Transportation, Energy, Food, etc.)
4. **Select specific activity** (Car Travel, Electricity Usage, etc.)
5. **Enter value** (distance, consumption, weight, etc.)
6. **Add optional details** (location, notes)
7. **Submit** to calculate and save carbon impact

### Setting Goals

1. **Navigate to Carbon Footprint page**
2. **Select "Goals" tab**
3. **Click "Add New Goal"**
4. **Enter goal details**:
   - Title and description
   - Target value and unit
   - Category
   - Start and end dates
5. **Save goal** to start tracking progress

### Viewing Analytics

1. **Navigate to Carbon Footprint page**
2. **Select "Analytics" tab**
3. **View**:
   - Weekly, monthly, yearly averages
   - Category breakdown
   - Trend analysis
   - Global comparisons

### Checking Insights

1. **Navigate to Carbon Insights page**
2. **Explore**:
   - User level and points
   - Achievements and progress
   - Personalized recommendations
   - Leaderboard rankings

## Database Structure

### Firebase Realtime Database

#### carbon_footprint
```json
{
  "entry_id": {
    "userId": "user123",
    "activityType": "Car Travel (Gasoline)",
    "value": 25.0,
    "unit": "km",
    "carbonImpact": 10.1,
    "date": 1640995200000,
    "notes": "Daily commute",
    "category": "Transportation",
    "subcategory": "Personal Vehicle",
    "emissionFactor": 0.404,
    "location": "New York",
    "isVerified": false
  }
}
```

#### carbon_goals
```json
{
  "goal_id": {
    "userId": "user123",
    "title": "Reduce Transportation Emissions",
    "description": "Use public transport more often",
    "targetValue": 5.0,
    "unit": "kg CO2",
    "startDate": 1640995200000,
    "endDate": 1643587200000,
    "category": "Transportation",
    "isActive": true,
    "currentProgress": 2.5,
    "status": "on_track"
  }
}
```

## API Endpoints

### Carbon Footprint Operations
- `getUserEntries(userId)` - Get all entries for a user
- `addEntry(entry)` - Add new carbon footprint entry
- `updateEntry(entry)` - Update existing entry
- `deleteEntry(key)` - Delete entry
- `getEntriesByDateRange(userId, startDate, endDate)` - Get filtered entries

### Goal Operations
- `getUserGoals(userId)` - Get all goals for a user
- `addGoal(goal)` - Add new goal
- `updateGoal(goal)` - Update existing goal
- `deleteGoal(key)` - Delete goal

### Analytics Operations
- `getUserAnalytics(userId)` - Get comprehensive analytics
- `calculateCarbonImpact(activityType, value)` - Calculate impact for activity

### Insights Operations
- `getUserInsights(userId)` - Get personalized insights
- `getLeaderboard()` - Get leaderboard data
- `getChallenges()` - Get available challenges

## Configuration

### Regional Settings
The system supports different emission factors based on region:
- **US**: Standard EPA emission factors
- **EU**: European emission factors
- **Asia**: Asian emission factors

### Target Settings
- **Default target**: 5.0 kg CO2/day
- **Customizable**: Users can set personal targets
- **Progressive**: Targets can be adjusted over time

## Security

### Data Privacy
- **User-specific data**: All entries are tied to user ID
- **Optional location**: Location data is optional and user-controlled
- **Verification system**: Entries can be marked as verified

### Access Control
- **Authentication required**: All carbon features require login
- **User isolation**: Users can only access their own data
- **Admin features**: Separate admin routes for management

## Performance

### Optimization
- **Lazy loading**: Data loaded on demand
- **Caching**: Analytics cached for performance
- **Pagination**: Large datasets paginated
- **Offline support**: Basic functionality works offline

### Scalability
- **Firebase integration**: Scalable cloud database
- **Efficient queries**: Optimized database queries
- **Background processing**: Heavy calculations done in background

## Testing

### Unit Tests
- Carbon calculation accuracy
- Goal progress tracking
- Analytics calculations
- Achievement system

### Integration Tests
- Database operations
- API endpoints
- User workflows
- Cross-page navigation

## Future Enhancements

### Planned Features
1. **Carbon offset integration**: Direct offset purchases
2. **Team challenges**: Group carbon reduction challenges
4. **Advanced analytics**: Machine learning insights
5. **API integrations**: Connect with other sustainability apps
6. **Gamification**: More advanced achievement system
7. **Educational content**: In-app sustainability education
8. **Carbon marketplace**: Buy/sell carbon credits

### Technical Improvements
1. **Real-time updates**: Live data synchronization
2. **Advanced charts**: Interactive data visualizations
3. **Export features**: PDF/CSV export capabilities
4. **Notifications**: Goal reminders and achievements
5. **Offline mode**: Full offline functionality
6. **Performance optimization**: Faster loading times

## Support

### Documentation
- This integration guide
- API documentation
- User guides
- Developer documentation

### Troubleshooting
- Common issues and solutions
- Debugging guide
- Performance optimization tips
- Data migration procedures

## Conclusion

The carbon footprint integration provides a comprehensive solution for tracking, analyzing, and reducing carbon emissions. With its scientific approach, user-friendly interface, and social features, it encourages sustainable living while providing valuable insights into personal environmental impact.

The system is designed to be scalable, secure, and user-friendly, making it an effective tool for promoting environmental consciousness and sustainable practices. 