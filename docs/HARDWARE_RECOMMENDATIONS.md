# Hardware Recommendations for Development & Testing

## Development Workstation

**Minimum Requirements:**
- MacBook Pro 16" M1/M2 or Linux workstation
- 16GB RAM (32GB recommended)
- 500GB SSD storage
- Android Studio installed
- AWS CLI v2

**Estimated Cost:** $1,500 - $2,500

## Android Test Devices

### Primary Development Device
**Google Pixel 8**
- Latest Android OS
- Clean Android experience
- Reliable sensors
- Good developer support
- Cost: ~$699

### Cross-Platform Testing
**Samsung Galaxy S23**
- Different sensor implementations
- Samsung-specific features
- Large market share
- Cost: ~$799

### Budget Device Testing
**Motorola Moto G Power**
- Lower-end hardware
- Battery performance testing
- Representative of budget market
- Cost: ~$199

### Tablet Testing (Optional)
**Samsung Galaxy Tab A9**
- Different form factor
- Larger screen testing
- Cost: ~$149

**Total Android Devices:** $1,846

## Wearables & Sensors

### Research-Grade Heart Rate Monitor
**Polar H10 Chest Strap**
- Bluetooth connectivity
- Accurate HR measurement
- Research validated
- Cost: ~$89

### Fitness Tracker
**Fitbit Charge 6**
- Google Fit integration
- Multiple sensors
- Popular consumer device
- Cost: ~$159

### Budget Wearable
**Xiaomi Mi Band 8**
- Low-cost testing
- Large user base
- Basic sensors
- Cost: ~$49

### Advanced Fitness Watch (Optional)
**Garmin Forerunner 265**
- Advanced metrics
- Multi-sport tracking
- Research-grade data
- Cost: ~$449

### Programmable Sensor (Optional)
**Movesense HR+ Sensor**
- Research-focused
- Programmable
- Multiple sensors
- Cost: ~$199

**Total Wearables:** $945 (basic) or $1,394 (full)

## Hardware Budgets

### Minimal Setup ($1,200)
- 1x Pixel 8: $699
- 1x Budget Android: $199
- 1x Polar H10: $89
- 1x Mi Band: $49
- **Total: $1,036**

### Recommended Setup ($3,000)
- 1x Pixel 8: $699
- 1x Galaxy S23: $799
- 1x Moto G Power: $199
- 1x Polar H10: $89
- 1x Fitbit Charge 6: $159
- 1x Mi Band 8: $49
- **Total: $1,994**

### Research Lab Setup ($5,000+)
- 2x Pixel 8: $1,398
- 1x Galaxy S23: $799
- 1x Moto G Power: $199
- 1x Tablet: $149
- 2x Polar H10: $178
- 1x Fitbit Charge 6: $159
- 1x Garmin Forerunner: $449
- 1x Movesense: $199
- 1x Mi Band: $49
- **Total: $3,579**

## AWS Development Costs

### Development Phase (4 months)
- EC2 (optional): ~$20/month
- Lambda: ~$10/month
- DynamoDB: ~$15/month
- S3: ~$10/month
- API Gateway: ~$5/month
- CloudWatch: ~$10/month
- **Total: ~$70/month × 4 = $280**

### Testing Phase (2 months)
- Higher usage for testing
- ~$150/month × 2 = $300

**Total AWS Dev/Test: ~$580**

## Total Investment

**Minimal:** ~$1,816
**Recommended:** ~$2,874
**Research Lab:** ~$4,459

## Procurement Strategy

### Week 1
- Order Pixel 8 (primary development)
- Set up AWS account

### Week 2-3
- Order budget Android device
- Order Polar H10

### Week 4-8
- Order Galaxy S23 (cross-platform testing)
- Order fitness trackers as needed

### Week 9+
- Order additional wearables based on integration priorities

## Device Management

### Organization
- Label each device clearly (DEV-1, TEST-1, etc.)
- Maintain device inventory spreadsheet
- Track Android versions and updates
- Document device-specific issues

### Charging & Storage
- USB charging hub for multiple devices
- Secure storage for test devices
- Backup devices for critical testing

### SIM Cards (Optional)
- For cellular connectivity testing
- Prepaid data plans
- Not required for WiFi-only testing

## Testing Accessories

### Recommended
- USB-C cables (multiple): ~$30
- USB charging hub: ~$40
- Bluetooth range extender: ~$25
- Power meter (for battery testing): ~$50

**Total Accessories: ~$145**

## Long-Term Considerations

### Device Refresh Cycle
- New Android OS every year
- Test on latest OS versions
- Replace devices every 2-3 years
- Budget ~$500/year for updates

### Wearable Updates
- Firmware updates
- New sensor models
- API changes
- Budget ~$200/year

### Cloud Costs
- Production deployment: $300-500/month per 100 participants
- Development/staging: $50-100/month ongoing
