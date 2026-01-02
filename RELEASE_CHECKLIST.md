# AsyncFlow 1.0.0 Release Checklist

## Pre-Release

### Code Quality
- [x] All tests passing
- [x] SwiftLint warnings resolved
- [x] Memory leaks checked
- [x] Thread safety verified
- [x] Code coverage reviewed
- [x] Performance profiling done

### Documentation
- [x] README.md complete (Korean)
- [x] README_EN.md complete (English)
- [x] API documentation complete (DocC)
- [x] Code examples added
- [x] CONTRIBUTING.md created
- [x] CHANGELOG.md updated
- [x] LICENSE file present

### Repository Setup
- [x] GitHub Issue templates created
  - [x] Bug report template
  - [x] Feature request template
- [x] CI/CD workflows configured
  - [x] GitHub Actions CI
  - [x] GitHub Actions Release
- [x] Branch protection rules set
- [x] .gitignore configured
- [x] .swiftlint.yml configured

### Package Configuration
- [x] Package.swift configured correctly
- [x] Platforms specified (iOS 15.0+, macOS 12.0+)
- [x] Swift language mode set to 6
- [x] Dependencies declared (none for core)
- [x] Test targets configured

### Example App
- [x] AsyncFlowExample working
- [x] All features demonstrated
- [x] UI polished
- [x] Comments added
- [x] README section added

### Testing
- [x] Unit tests complete
- [x] Integration tests complete
- [x] UI tests added (example app)
- [x] Edge cases covered
- [x] Test utilities provided (FlowTestStore, MockStepper)

## Release Process

### Version Management
- [ ] Update version in Package.swift
- [ ] Update version in Project.swift files
- [ ] Update CHANGELOG.md with release date
- [ ] Create git tag `1.0.0`

### GitHub Release
- [ ] Create release on GitHub
- [ ] Upload release notes from CHANGELOG
- [ ] Mark as latest release
- [ ] Verify package resolution works

### Documentation Deployment
- [ ] Build DocC documentation
- [ ] Deploy to GitHub Pages
- [ ] Verify documentation accessible
- [ ] Update README links

### Communication
- [ ] Tweet announcement
- [ ] Post on Swift Forums
- [ ] Post on Reddit r/swift
- [ ] Update personal website/blog

## Post-Release

### Monitoring
- [ ] Monitor GitHub issues
- [ ] Monitor GitHub discussions
- [ ] Check CI/CD status
- [ ] Review analytics (if available)

### Community
- [ ] Respond to initial feedback
- [ ] Update FAQ based on questions
- [ ] Plan next version features
- [ ] Thank contributors

---

## Commands

### Create Tag
```bash
git tag -a 1.0.0 -m "Release 1.0.0"
git push origin 1.0.0
```

### Test Package Resolution
```bash
# Create test project
mkdir TestAsyncFlow
cd TestAsyncFlow
swift package init --type executable

# Add dependency
cat > Package.swift << 'EOF'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TestAsyncFlow",
    platforms: [.iOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/Jimmy-Jung/AsyncFlow", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "TestAsyncFlow",
            dependencies: ["AsyncFlow"]
        )
    ]
)
EOF

# Resolve
swift package resolve
```

### Build Documentation
```bash
tuist install
tuist generate

xcodebuild docbuild \
  -scheme AsyncFlow \
  -destination 'generic/platform=iOS' \
  -derivedDataPath DerivedData

$(xcrun --find docc) process-archive \
  transform-for-static-hosting \
  DerivedData/Build/Products/Debug-iphoneos/AsyncFlow.doccarchive \
  --output-path docs \
  --hosting-base-path AsyncFlow
```

---

## Notes

- Release should be done on a **Friday** for weekend monitoring
- Announce release in **morning (KST)** for maximum visibility
- Monitor for at least **48 hours** after release
- Be prepared for hotfix if critical issues found

---

Created: 2025-01-02
Last Updated: 2025-01-02
Status: Ready for Release 🚀

