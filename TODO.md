# OSRP - Remaining Tasks

Tasks that still need to be completed for the full rebrand and launch.

---

## 🔴 High Priority

### Documentation Updates (Still Using Old Names)

- [x] **docs/PROJECT_BRIEF.md** ✅
  - Replace "Mobile Sensing Platform" with "OSRP"
  - Update terminology throughout

- [x] **docs/TECHNICAL_SPECIFICATION.md** ✅
  - Update all references to "Mobile Sensing Platform"
  - Update package names and class names
  - Update example code snippets

- [x] **docs/IMPLEMENTATION_PLAN.md** ✅
  - Update project name
  - Update package structure references
  - Update deployment commands

- [x] **GETTING_STARTED.md** ✅
  - Comprehensive rewrite with OSRP branding
  - Update CLI commands
  - Update example code

- [ ] **templates/lambda_function_template.py**
  - Add OSRP header comment
  - Update package references

- [ ] **infrastructure/README.md**
  - Update project references
  - Update stack naming conventions

### Python Package Structure

- [ ] **Move analysis/ into osrp/ package**
  - Current: `osrp/analysis/utils/data_access.py`
  - Target: `osrp/osrp/analysis/utils/data_access.py`
  - Update imports in notebooks
  - Update setup.py package discovery

- [ ] **Fix import paths**
  - Notebooks currently use: `from data_access import OSRPData`
  - Should be: `from osrp import OSRPData`
  - Or: `from osrp.analysis.utils import OSRPData`

### Testing

- [ ] **Test pip installation**
  - Create test environment
  - Install package: `pip install -e .`
  - Verify imports work
  - Test CLI commands

- [ ] **Test notebooks**
  - Verify all three notebooks run without errors
  - Check imports resolve correctly
  - Validate data access works

- [ ] **Test CLI**
  - Test `osrp init`
  - Test `osrp deploy` (dry run)
  - Test `osrp notebooks`
  - Test `osrp status`
  - Test `osrp info`

---

## 🟡 Medium Priority

### GitHub Setup

- [x] **Create GitHub organization** ✅
  - Name: `open-sensor-research-platform`
  - Create repositories:
    - `osrp` (main repo) ✅
    - `docs` (documentation site) - Future
    - `examples` (example studies) - Future
    - `android-app` (Android application) - Future

- [x] **Configure repository** ✅
  - Add README.md ✅
  - Add LICENSE (Apache 2.0) ✅
  - Add topics for discoverability ✅
  - Add CONTRIBUTING.md - Future
  - Add CODE_OF_CONDUCT.md - Future
  - Add GitHub Actions workflows - Future
  - Add issue templates - Future
  - Add PR template - Future

- [ ] **Set up GitHub Pages**
  - Configure docs.osrp.io
  - Build documentation site
  - Deploy landing page

### Domain & Website

- [x] **Purchase domain** ✅
  - osrp.io (primary) ✅

- [x] **Build landing page** ✅
  - Use LANDING_PAGE.md as content source ✅
  - Professional HTML/CSS design ✅
  - Implement responsive design ✅
  - Deploy to osrp.io ✅
  - GitHub Pages enabled ✅

- [ ] **Documentation site**
  - Convert markdown docs to web format
  - Add search functionality
  - Add navigation
  - Deploy to docs.osrp.io

### ⚠️ Package Publishing - NOT READY YET

**Do NOT publish to PyPI until the system actually works!**

Current status:
- Package structure exists ✅
- OSRPData class is a skeleton (no data to access yet) ❌
- CLI commands are mostly placeholders ❌
- No Android app ❌
- No AWS infrastructure deployed ❌
- No data collection happening ❌

**Publish to PyPI ONLY after:**
- [ ] Android app built and working
- [ ] AWS infrastructure deployed and tested
- [ ] End-to-end data collection working
- [ ] OSRPData returns real data from deployed system
- [ ] Pilot study completed successfully

### Android App - CRITICAL TO BUILD

- [ ] **Build Android app** (16-week plan)
  - Week 1-4: Foundation (AWS + project structure + screenshots + app usage)
  - Week 5-8: Sensors (built-in sensors + device state + data pipeline)
  - Week 9-12: Wearables & EMA (Google Fit + Bluetooth + surveys)
  - Week 13-16: Testing & deployment

- [ ] **Configure for OSRP branding**
  - Package name: `io.osrp.app`
  - App name: "OSRP"
  - Update all string resources
  - Create icon and splash screen

---

## 🟢 Lower Priority

### Content Creation

- [ ] **Demo video**
  - 5-minute overview
  - Show data collection
  - Show analysis notebooks
  - Show deployment

- [ ] **Tutorial videos**
  - Installation and setup
  - Creating your first study
  - Analyzing data with Marimo
  - Deploying to AWS

- [ ] **Blog posts**
  - "Introducing OSRP"
  - "OSRP vs AWARE vs Beiwe"
  - "Multi-modal digital phenotyping"
  - "Building on AWS with OSRP"

### Community Building

- [ ] **Social media presence**
  - Twitter: @osrp_platform
  - LinkedIn: OSRP page
  - Reddit: r/digitalpheno

- [ ] **Academic outreach**
  - Email Stanford research groups
  - Email MIT Media Lab
  - Email UCLA psychology dept
  - Present at conferences

- [ ] **AWS partnership**
  - Apply for AWS Research Credits
  - AWS blog post collaboration
  - AWS case study

### Features & Improvements

- [ ] **Additional notebooks**
  - Sleep analysis
  - Social media usage patterns
  - Stress prediction model
  - Location clustering

- [ ] **CLI improvements**
  - `osrp export` command (export data)
  - `osrp validate` command (check configuration)
  - `osrp monitor` command (real-time monitoring)
  - `osrp participants` command (list/manage participants)

- [ ] **Analysis features**
  - Time zone handling
  - Missing data imputation
  - Advanced feature engineering
  - Model deployment helpers

---

## 📋 Checklist for v0.1.0 Release

### Code Complete
- [x] Core package structure
- [x] OSRPData class
- [x] CLI implementation
- [x] Example notebooks
- [ ] All documentation updated
- [ ] Tests passing
- [ ] Package installable

### Distribution
- [ ] PyPI package published
- [ ] GitHub repository public
- [ ] Docker image (optional)
- [ ] AWS Marketplace listing (optional)

### Documentation
- [x] README.md comprehensive
- [x] QUICK_START.md created
- [x] LANDING_PAGE.md created
- [ ] All docs/ files updated
- [ ] API reference generated
- [ ] Contributing guide

### Marketing
- [ ] Landing page live at osrp.io
- [ ] Documentation site at docs.osrp.io
- [ ] Demo video published
- [ ] Blog post published
- [ ] Social media announcement

---

## 🎯 Launch Timeline

### Week 1: Complete Rebrand ✅
- [x] Core code rebrand ✅
- [x] Update all documentation ✅
- [x] Test package installation ✅
- [x] Fix any import issues ✅

### Week 2: GitHub & Domain ✅
- [x] Create GitHub organization ✅
- [x] Push code to public repo ✅
- [x] Purchase osrp.io domain ✅
- [x] Set up GitHub Pages ✅

### Week 3: Package & Website (In Progress)
- [ ] Publish to PyPI
- [x] Build landing page ✅
- [ ] Deploy documentation site
- [ ] Create demo video

### Week 4: Launch
- [ ] Soft launch (blog post, social media)
- [ ] Reach out to universities
- [ ] Submit to AWS Research Credits
- [ ] Monitor feedback

---

## Notes for Future Development

### v0.2.0 Features
- Real-time interventions
- Advanced ML pipelines
- Researcher dashboard (web UI)
- Multi-study management
- Enhanced security features

### v0.3.0 Features
- iOS support (limited - no screenshots)
- Additional wearables support
- Federated learning
- Edge ML inference
- Multi-cloud support

### Long-term Vision
- Hosted SaaS version (cloud.osrp.io)
- Enterprise features
- Commercial support options
- Integration with other platforms
- Grant-funded development

---

**Current Status**: Core rebrand complete ✅
**Next Step**: Update remaining documentation files
**Target Launch**: 4 weeks from completion

**Contact**: For questions or contributions, see CONTRIBUTING.md (to be created)
