# Plan: Replicate GitHub Default CodeQL Locally

## 🎯 **Objective**

Create a local CodeQL setup that **exactly mirrors** GitHub Actions' default CodeQL behavior, providing the same analysis, results, and workflow as GitHub's cloud-based CodeQL.

## 🔍 **Current Gap Analysis**

### ❌ **What's Broken Now**

1. **Database Creation Issues**
    - Timeout errors during database creation (5-10 minutes)
    - Permission errors with `.codeql` directory files
    - Analyzing CodeQL example files instead of project code

2. **Configuration Mismatch**
    - Local script uses direct query files vs GitHub's config-based approach
    - Missing proper path filtering during database creation
    - No equivalent to GitHub's automatic language detection

3. **Results Mismatch**
    - Local: 1608 findings (includes CodeQL examples)
    - GitHub: Expected ~100-200 real findings from actual project code
    - Different output formats (local SARIF vs GitHub's integration)

## 📖 **How GitHub Default CodeQL Actually Works**

### **GitHub Actions CodeQL Workflow Structure**

```yaml
# 1. Initialize CodeQL
- uses: github/codeql-action/init@v3
  with:
      languages: ${{ matrix.language }} # Auto-detected: ruby, javascript-typescript
      config-file: ./.github/codeql/codeql-config.yml

# 2. Build code (if needed)
- uses: github/codeql-action/autobuild@v3 # Or manual build steps

# 3. Analyze and upload
- uses: github/codeql-action/analyze@v3
```

### **Key GitHub Behaviors to Replicate**

1. **Language Auto-Detection**: Scans repository and detects supported languages
2. **Default Query Suite**: Uses `security-and-quality` suite automatically
3. **Proper Path Filtering**: Respects `paths-ignore` during analysis (not just database creation)
4. **SARIF Integration**: Produces properly formatted SARIF with GitHub metadata
5. **Matrix Strategy**: Analyzes each language in parallel/separately

## 🛠 **Implementation Plan**

### **Phase 1: Fix Core Infrastructure** (Days 1-2)

#### **1.1 Redesign Local Script Architecture**

- [ ] **Refactor `scripts/codeql-local.sh`** to mirror GitHub Actions steps:

    ```bash
    # New structure:
    setup_codeql()          # Install CLI + queries (once)
    detect_languages()      # Auto-detect like GitHub
    init_analysis()         # Use config file like GitHub
    build_if_needed()      # Autobuild for compiled languages
    analyze_language()     # Per-language analysis
    upload_results()       # Generate final SARIF
    ```

#### **1.2 Implement GitHub-Style Configuration**

- [ ] **Use config file for all settings** (not direct query references)
- [ ] **Implement proper path filtering** during analysis phase
- [ ] **Add language auto-detection** like GitHub Actions
- [ ] **Support matrix-style execution** (one language at a time)

#### **1.3 Fix Database Creation**

- [ ] **Increase timeouts** for large codebases
- [ ] **Implement incremental database creation** (cache between runs)
- [ ] **Add proper error handling** and retry logic
- [ ] **Optimize for local development** (faster subsequent runs)

### **Phase 2: Exact GitHub Replication** (Days 3-4)

#### **2.1 Language Detection & Matrix Strategy**

```bash
# Replicate GitHub's language detection
detect_supported_languages() {
    # Scan repository for supported language files
    # Return: ruby, javascript-typescript, etc.
}

# Replicate GitHub's matrix strategy
for language in $(detect_supported_languages); do
    run_codeql_analysis "$language"
done
```

#### **2.2 Configuration File Integration**

```bash
# Use config file exactly like GitHub Actions
codeql database analyze \
    --config-file=".github/codeql/codeql-config.yml" \
    --format=sarif-latest \
    --output="results-${language}.sarif"
```

#### **2.3 Build Mode Implementation**

- [ ] **Auto-detect build requirements** (compiled vs interpreted)
- [ ] **Implement autobuild for Ruby** (if gems need compilation)
- [ ] **Use `none` build mode for JavaScript/TypeScript**
- [ ] **Handle build errors gracefully**

### **Phase 3: Results & Integration** (Day 5)

#### **3.1 SARIF Processing**

- [ ] **Generate GitHub-compatible SARIF** with proper metadata
- [ ] **Merge multi-language results** into single report
- [ ] **Filter results using config file** `paths-ignore`
- [ ] **Add GitHub-style categorization** and severity mapping

#### **3.2 Output Formatting**

- [ ] **Human-readable summary** matching GitHub's format
- [ ] **VS Code integration** for viewing results
- [ ] **CI/CD integration** with proper exit codes
- [ ] **Comparison with GitHub results** for validation

### **Phase 4: Optimization & Validation** (Day 6)

#### **4.1 Performance Optimization**

- [ ] **Database caching** between runs
- [ ] **Incremental analysis** for changed files only
- [ ] **Parallel language processing** where possible
- [ ] **Resource usage optimization** (RAM, CPU)

#### **4.2 Validation Testing**

- [ ] **Compare results with GitHub Actions** (same codebase)
- [ ] **Verify SARIF compatibility**
- [ ] **Test all supported languages**
- [ ] **Validate configuration file behavior**

## 🎯 **Success Criteria**

### **✅ Primary Goals**

1. **Identical Results**: Local analysis produces same findings as GitHub Actions
2. **Same Configuration**: Uses identical config files and settings
3. **Proper Filtering**: Correctly excludes paths and test files
4. **Performance**: Completes analysis in reasonable time (<10 minutes)

### **✅ Secondary Goals**

1. **Developer Experience**: Easy to run and understand results
2. **CI Integration**: Works in automated pipelines
3. **Incremental Updates**: Fast re-analysis after code changes
4. **Documentation**: Clear setup and troubleshooting guides

## 📁 **Files to Modify**

### **Core Scripts**

- [ ] `scripts/codeql-local.sh` - Complete rewrite using GitHub Actions pattern
- [ ] `scripts/codeql-viewer.sh` - Update for new result format
- [ ] `scripts/static.pl` - Re-enable CodeQL integration

### **Configuration**

- [ ] `.github/codeql/codeql-config.yml` - Ensure GitHub compatibility
- [ ] `.github/workflows/codeql.yml.disabled` - Reference implementation

### **Documentation**

- [ ] `documentation/codeql_security_analysis.md` - Update with new process
- [ ] `CODEQL_SETUP_COMPLETE.md` - New completion guide

## 🚀 **Expected Outcome**

After implementation:

- ✅ **`scripts/codeql-local.sh`** produces identical results to GitHub Actions
- ✅ **Analysis time** reduced from timeout to <10 minutes
- ✅ **Finding count** reduced from 1608 to realistic ~100-200
- ✅ **Developer workflow** seamlessly integrates CodeQL locally
- ✅ **CI/CD pipeline** uses same CodeQL for consistent security scanning

## 📋 **Next Steps**

1. **Start with Phase 1.1** - Redesign script architecture
2. **Test incrementally** - Validate each component works
3. **Compare with GitHub** - Ensure identical behavior
4. **Document process** - Enable team adoption

This plan transforms the current broken local CodeQL into a production-ready security analysis tool that exactly matches GitHub's industry-standard implementation.
