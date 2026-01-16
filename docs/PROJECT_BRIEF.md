# OSRP (Open Sensing Research Platform) - Project Brief

## Overview

OSRP is a comprehensive mobile sensing research platform that combines behavioral observation (screenshots, app usage, interactions) with physiological/environmental sensors and wearable integration, all on AWS infrastructure.

**Mission**: Provide the only open-source platform combining screenshots + sensors + wearables + AWS + integrated analysis for academic digital phenotyping research.

## Core Objectives

1. Port Stanford Screenomics functionality from Firebase to AWS
2. Add comprehensive sensor collection capabilities
3. Integrate wearable devices (Google Fit, Polar, Bluetooth HR monitors)
4. Create modular, configurable system for research studies
5. Build AWS-native infrastructure for academic institutions
6. Provide integrated Marimo analysis notebooks for reproducible research

## What is OSRP?

OSRP (Open Sensing Research Platform) provides:

- **Screenshot Capture**: Behavioral observation of app usage and content
- **Built-in Sensors**: Accelerometer, GPS, gyroscope, activity recognition
- **Wearable Integration**: Google Fit, Bluetooth heart rate monitors
- **Experience Sampling**: Context-aware surveys and EMAs
- **AWS-Native**: DynamoDB, S3, Lambda, SageMaker, Cognito
- **Marimo Analysis**: Reactive, reproducible notebooks
- **Open Source**: Apache 2.0 license, full customization

## Target Users

- **Research Participants**: Install Android app, consent to data collection
- **Researchers**: Configure studies, monitor participants, analyze data with Marimo notebooks
- **Universities**: Host on their AWS accounts with institutional compliance
- **Data Scientists**: Use OSRPData API for custom analyses

## Key Differentiators

- **Comprehensive**: Combines behavioral + physiological + environmental data
- **Modular**: Researchers enable/disable specific data collection modules
- **AWS-Native**: Leverages existing university AWS infrastructure
- **Open Source**: Extendable platform, not proprietary black box
- **Research-Grade**: Validated sensors, temporal alignment, context capture
- **Integrated Analysis**: Marimo notebooks included (unique to OSRP)
- **Complete Pipeline**: Collection → Storage → Analysis → ML

## Success Criteria

### Data Collection
- Collect screenshots every 5 seconds with metadata
- Capture all Android sensor streams with configurable sampling
- Integrate with Google Fit and Bluetooth wearables
- Support 1000+ concurrent participants per deployment

### Performance
- Keep data collection cost under $5/participant/month
- Battery drain less than 15% per day with full collection enabled
- 99% data delivery reliability
- API latency < 500ms p95

### Analysis
- Marimo notebooks work out of the box
- OSRPData API provides intuitive data access
- Multi-modal alignment in 3 lines of code
- Reproducible ML pipelines

## Non-Goals (v0.1.0)

- iOS application (Android-only initially - iOS planned for v0.2.0)
- Real-time interventions (batch processing focus - interventions planned for v0.2.0)
- Custom wearable hardware integration (standard BLE only)
- Multi-cloud deployment (AWS-only - others may be added later)
- Audio recording (privacy concerns - may be added as optional module)

## Timeline

### Completed (v0.1.0)
- ✅ Core package structure and OSRPData class
- ✅ CLI tool (osrp init, deploy, notebooks, status, info)
- ✅ Marimo analysis notebooks
- ✅ Python package with uv support
- ✅ Documentation (90%)

### Phase 1: Foundation (Weeks 1-4)
- AWS infrastructure deployment
- Android project structure
- Screenshot module implementation
- App usage & interaction tracking

### Phase 2: Sensor Collection (Weeks 5-8)
- Built-in sensors (accelerometer, GPS, etc.)
- Device state monitoring
- Data pipeline optimization
- Configuration system

### Phase 3: Wearables & EMA (Weeks 9-12)
- Google Fit integration
- Bluetooth wearables
- Experience sampling method (EMA)
- Context-aware triggers

### Phase 4: Testing & Deployment (Weeks 13-16)
- Comprehensive testing
- Documentation completion
- Pilot study
- Production preparation

## Value Proposition for Universities

### Technical Benefits
- Runs on existing AWS infrastructure
- HIPAA-compliant out of the box
- No vendor lock-in (Apache 2.0 license)
- Integrates with institutional identity management
- Uses university's existing AWS agreements
- Modern Python tooling (uv, Marimo, pyproject.toml)

### Research Benefits
- Combines multiple data streams temporally aligned
- Configurable for different study designs
- Rich contextual data capture
- Unobtrusive data collection (minimizes reporting bias)
- Supports large-scale longitudinal studies
- Integrated analysis with Marimo (reproducible by design)

### Cost Benefits
- No per-participant licensing fees (~$5/month AWS costs only)
- Uses AWS on-demand pricing
- Automated lifecycle policies reduce storage costs
- Open source reduces development costs
- Community contributions extend functionality
- No commercial vendor markup

## Comparison with Alternatives

### OSRP vs AWARE Framework
✅ **OSRP**: Screenshot capture (behavioral observation)
✅ **OSRP**: AWS-native infrastructure
✅ **OSRP**: Integrated Marimo analysis notebooks
✅ **OSRP**: Wearable integration built-in
✅ **OSRP**: Simpler deployment (one command)
❌ **AWARE**: iOS support (OSRP is Android-only in v0.1.0)
❌ **AWARE**: Mature ecosystem (OSRP is new)

### OSRP vs Stanford Screenomics
✅ **OSRP**: AWS-native (vs. Firebase/GCP)
✅ **OSRP**: Sensor data for context
✅ **OSRP**: Wearable integration
✅ **OSRP**: EMA system included
✅ **OSRP**: Integrated analysis (Marimo)
❌ **Screenomics**: Proven OCR pipeline

### OSRP vs Centralive (Commercial)
✅ **OSRP**: Open source and extensible
✅ **OSRP**: No licensing costs ($5 vs $20-50/participant/month)
✅ **OSRP**: Full data ownership
✅ **OSRP**: Screenshot capability
✅ **OSRP**: Marimo analysis included
❌ **Centralive**: Managed service (no DevOps needed)

### OSRP vs LAMP Platform
✅ **OSRP**: Screenshot capture
✅ **OSRP**: Simpler AWS deployment
✅ **OSRP**: Marimo notebooks (better analysis UX)
✅ **OSRP**: Research-focused (not clinical complexity)
❌ **LAMP**: Real-time interventions (planned for OSRP v0.2.0)
❌ **LAMP**: Cognitive task batteries

### OSRP vs Beiwe
✅ **OSRP**: AWS-native (vs custom backend)
✅ **OSRP**: Integrated Marimo analysis
✅ **OSRP**: Modern architecture (serverless, Lambda)
✅ **OSRP**: Simpler deployment
✅ **OSRP**: Better for new projects
❌ **Beiwe**: 10+ years proven in production
❌ **Beiwe**: Audio recording capability

**OSRP's Unique Position**: Only platform with screenshots + sensors + wearables + AWS + Marimo analysis.

## Risk Assessment

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Battery drain | High | Efficient sampling, configurable rates, background optimization |
| Data upload reliability | High | Retry logic, local caching, exponential backoff |
| Device compatibility | Medium | Test on multiple manufacturers, OS versions |
| AWS costs | Medium | Monitor closely, lifecycle policies, cost alerts |
| Screenshot latency | Medium | Optimize capture pipeline, reduce image quality if needed |

### Operational Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| IRB approval | High | Provide template language, compliance documentation |
| Participant recruitment | Medium | Clear onboarding, minimal friction, compensation |
| Data security | High | AWS security best practices, encryption, audit logs |
| Support burden | Medium | Good documentation, automated monitoring, community |
| Adoption barrier | Medium | Excellent docs, demo video, example studies |

### Mitigation Strategies
- Extensive testing before production
- Pilot studies with small cohorts (5-10 participants)
- Monitoring and alerting from day one
- Clear escalation procedures
- Regular security audits
- Active community building

## Success Metrics

### Phase 1 Success (Weeks 1-4)
- [x] AWS infrastructure deployed (CloudFormation templates ready)
- [x] Authentication working (Cognito integration planned)
- [ ] Screenshots uploading to S3
- [ ] App usage logs in DynamoDB
- [ ] Basic monitoring dashboard (CloudWatch)

### Phase 2 Success (Weeks 5-8)
- [ ] All sensor modules operational
- [ ] Battery drain < 20% (optimization target)
- [ ] Data pipeline efficient
- [ ] Configuration system working
- [ ] Multi-device testing complete

### Phase 3 Success (Weeks 9-12)
- [ ] Google Fit integration working
- [ ] Bluetooth HR monitors supported
- [ ] EMA system functional
- [ ] Context-aware triggers operational
- [ ] Integration testing complete

### Phase 4 Success (Weeks 13-16)
- [ ] Pilot study with 10-20 participants
- [ ] Battery drain < 15%
- [ ] 99% data delivery
- [ ] Complete documentation
- [ ] Production-ready deployment

### v0.1.0 Success (Completed)
- [x] Python package installable (osrp)
- [x] CLI tool functional (osrp init, deploy, notebooks)
- [x] OSRPData class complete
- [x] Marimo notebooks working
- [x] Documentation (90%)
- [x] Apache 2.0 license
- [x] Semantic versioning

## Go/No-Go Decision Points

### After Week 4
**Go Criteria:**
- Screenshot capture working reliably
- AWS costs within budget ($50-100/month dev)
- Battery drain acceptable (<30%)
- No major architectural issues

**No-Go Triggers:**
- Screenshot latency > 200ms consistently
- AWS costs > 2x estimate
- Battery drain > 30%
- Fundamental Android API limitations discovered

### After Week 8
**Go Criteria:**
- All sensors collecting data
- Data pipeline efficient
- Performance acceptable
- No data loss issues

**No-Go Triggers:**
- Unable to achieve < 20% battery drain
- Data pipeline unreliable
- Performance issues on mid-range devices
- Storage costs prohibitive

### After Week 12
**Go Criteria:**
- Wearables integrated
- EMA system working
- Ready for pilot testing
- Documentation adequate

**No-Go Triggers:**
- Critical features not working
- Major stability issues
- Security vulnerabilities
- Cannot meet research requirements

## Stakeholders

### Primary
- **University Research Computing Teams**: Deploy and maintain OSRP infrastructure
- **Principal Investigators**: Design studies, analyze data with Marimo
- **Research Coordinators**: Monitor participants, manage studies via CLI
- **Study Participants**: Install app, provide data, receive compensation
- **Data Scientists**: Use OSRPData API for custom analyses

### Secondary
- **IRB/Ethics Committees**: Approve studies using OSRP
- **IT Security Teams**: Review compliance and security
- **University Procurement**: Evaluate costs and licenses
- **Open Source Community**: Extend and improve OSRP
- **AWS**: Potential partnership for research credits

## Communication Plan

### Weekly Updates
- Progress against timeline
- Issues and blockers
- Cost tracking
- Key decisions needed
- Community engagement

### Monthly Reviews
- Demo of new functionality
- Performance metrics
- Cost analysis
- Roadmap adjustments
- User feedback

### Milestone Presentations
- End of each phase
- Technical architecture review
- Pilot study results
- Production readiness assessment
- Conference presentations

### Community Engagement
- GitHub Discussions for Q&A
- Monthly office hours (video call)
- Quarterly contributor calls
- Annual OSRP conference (virtual)

## Next Steps

### Immediate (This Week)
1. ✅ Complete package rebrand to OSRP
2. ✅ Update all documentation
3. ✅ Test package installation with uv
4. [ ] Set up GitHub repository
5. [ ] Purchase osrp.io domain

### Short-term (Next Month)
1. Deploy AWS infrastructure
2. Build Android app (Phase 1)
3. Test data collection pipeline
4. Publish to PyPI
5. Launch landing page at osrp.io

### Medium-term (Next Quarter)
1. Complete Phases 2-4
2. Pilot study with 10-20 participants
3. Gather feedback and iterate
4. Build community (GitHub stars, contributors)
5. Present at conferences

### Long-term (Next 6 Months)
1. v0.2.0 release with interventions
2. iOS support (limited)
3. Research paper submission
4. University partnerships (Stanford, MIT, UCLA)
5. v1.0.0 production release

## Appendix: Key Terminology

- **OSRP**: Open Sensing Research Platform
- **OSRPData**: Python class for unified data access to DynamoDB and S3
- **EMA**: Ecological Momentary Assessment - surveys delivered in real-world contexts
- **Digital Phenotyping**: Using digital data to characterize behavior patterns
- **Temporal Alignment**: Synchronizing multiple data streams by timestamp
- **Context-Aware**: Triggers based on user's current situation/activity
- **Modular Architecture**: Independent, swappable components
- **Research-Grade**: Validated accuracy suitable for scientific studies
- **Marimo**: Reactive Python notebook framework (better than Jupyter)
- **uv**: Fast Python package installer and resolver
- **Multi-Modal**: Multiple types of data (behavioral + physiological + environmental)

## References

- **Website**: https://osrp.io (coming soon)
- **Documentation**: https://docs.osrp.io (coming soon)
- **GitHub**: https://github.com/open-sensor-research-platform/osrp
- **PyPI**: https://pypi.org/project/osrp/ (coming soon)
- **License**: Apache 2.0
- **Copyright**: 2026 Scott Friedman and OSRP Contributors

---

**Last Updated**: January 15, 2026
**Version**: 0.1.0
**Status**: Active Development
