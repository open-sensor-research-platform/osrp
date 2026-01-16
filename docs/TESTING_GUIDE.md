# Testing Guide

## Overview
Comprehensive testing strategy for the Mobile Sensing Platform.

## Unit Testing

### Android Unit Tests
Location: `/android/app/src/test/kotlin/`

Run tests:
```bash
cd android
./gradlew test
./gradlew testDebugUnitTest
```

### Lambda Unit Tests
Location: `/tests/lambda/`

Run tests:
```bash
cd tests/lambda
python -m pytest -v
```

## Integration Testing

### End-to-End Flow Tests
Test complete data flow from capture to storage in AWS.

### Performance Testing
- Screenshot capture latency
- Memory usage monitoring  
- Battery drain measurement

### Load Testing AWS Infrastructure
Simulate multiple concurrent participants.

## Manual Testing Protocols

### Battery Drain Test
1. Fully charge device to 100%
2. Install app with all modules enabled
3. Run for 24 hours with normal usage
4. Record battery level every hour

Target: < 15% additional drain per day

### Data Completeness Test
1. Run app for 24 hours
2. Validate all expected data collected
3. Check temporal alignment
4. Verify no data gaps

Target: > 95% completeness

## Validation Scripts

See `/tests/validation/` for data validation scripts.

## Test Devices

- Pixel 8 (primary)
- Galaxy S23 (cross-platform)
- Moto G Power (budget device)
- Wearables (Polar H10, Fitbit, etc.)
