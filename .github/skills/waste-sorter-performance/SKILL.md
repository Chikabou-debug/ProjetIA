---
name: waste-sorter-performance
description: "Use when: optimizing waste sorter app performance, profiling, improving build time, reducing memory usage, or analyzing API latency"
tags:
  - flutter
  - performance
  - optimization
  - waste-sorter
triggers:
  - "performance"
  - "optimize"
  - "slow"
  - "latency"
  - "memory"
  - "build time"
---

# Waste Sorter App Performance Optimization Skill

Helps optimize the EcoTri AI waste sorter Flutter application for better performance, reduced resource usage, and faster response times.

## What This Skill Does

- **Profiling**: Analyze Flutter performance metrics (frame rate, memory, CPU)
- **Build Optimization**: Reduce APK/IPA size and build time
- **API Performance**: Identify slow endpoints and optimize requests
- **Widget Rendering**: Fix jank and improve UI responsiveness
- **Asset Management**: Optimize image loading and caching
- **Database**: Profile SQLite queries and improve data access patterns

## Common Tasks

### 1. Profile the App
```bash
# Run with performance profiling
flutter run -v --profile

# Use DevTools
dart devtools
```

### 2. Analyze Build Size
```bash
# Check APK/IPA size breakdown
flutter build apk --split-debug-info=build/app.android-symbols
flutter build ios --release
```

### 3. Check Memory Usage
- Use Android Studio Profiler
- Use Xcode Instruments (iOS)
- Check SharedPreferences and cached data

### 4. Optimize Images
- Use WebP format instead of PNG for smaller file sizes
- Add caching headers for API responses
- Implement image resizing before upload

## Key Files to Analyze

- `lib/main.dart` - Main app structure and navigation
- `waste_sorter_app/lib/` - Widget implementations
- `api.py` - Backend API endpoints

## Performance Goals

- Frame rate: ≥ 60 FPS (smooth scrolling)
- API response time: < 2s for image classification
- Memory usage: < 150MB on average devices
- APK size: < 100MB

## Next Steps

1. Run a profile build to identify hotspots
2. Check API response times with slow 3G simulation
3. Profile widget builds with DevTools Performance tab
4. Implement recommendations from profiling results
