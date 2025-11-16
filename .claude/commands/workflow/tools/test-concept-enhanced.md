---
name: test-concept-enhanced
description: Analyze test requirements and generate test generation strategy using Gemini with test-context package
argument-hint: "--session WFS-test-session-id --context path/to/test-context-package.toon"
examples:
  - /workflow:tools:test-concept-enhanced --session WFS-test-auth --context .workflow/WFS-test-auth/.process/test-context-package.toon
---
> **TOON Format Default**
> - Encode structured artifacts with `encodeTOON` or `scripts/toon-wrapper.sh encode` into `.toon` files.
> - Load artifacts with `autoDecode`/`decodeTOON` (or `scripts/toon-wrapper.sh decode`) to auto-detect TOON vs legacy `.json`.
> - When instructions mention JSON outputs, treat TOON as the default format while keeping legacy `.json` readable.


# Test Concept Enhanced Command

## Overview
Specialized analysis tool for test generation workflows that uses Gemini to analyze test coverage gaps, implementation context, and generate comprehensive test generation strategies.

## Core Philosophy
- **Coverage-Driven**: Focus on identified test gaps from context analysis
- **Pattern-Based**: Learn from existing tests and project conventions
- **Gemini-Powered**: Use Gemini for test requirement analysis and strategy design
- **Single-Round Analysis**: Comprehensive test analysis in one execution
- **No Code Generation**: Strategy and planning only, actual test generation happens in task execution

## Core Responsibilities
- Parse test-context-package.toon from test-context-gather
- Analyze implementation summaries and coverage gaps
- Study existing test patterns and conventions
- Generate test generation strategy using Gemini
- Produce TEST_ANALYSIS_RESULTS.md for task generation

## Execution Lifecycle

### Phase 1: Validation & Preparation

1. **Session Validation**
   - Load `.workflow/{test_session_id}/workflow-session.toon`
   - Verify test session type is "test-gen"
   - Extract source session reference

2. **Context Package Validation**
   - Read `test-context-package.toon`
   - Validate required sections: metadata, source_context, test_coverage, test_framework
   - Extract coverage gaps and framework details

3. **Strategy Determination**
   - **Simple Test Generation** (1-3 files): Single Gemini analysis
   - **Medium Test Generation** (4-6 files): Gemini comprehensive analysis
   - **Complex Test Generation** (>6 files): Gemini analysis with modular approach

### Phase 2: Gemini Test Analysis

**Tool Configuration**:
```bash
cd .workflow/{test_session_id}/.process && gemini -p "
PURPOSE: Analyze test coverage gaps and design comprehensive test generation strategy
TASK: Study implementation context, existing tests, and generate test requirements for missing coverage
MODE: analysis
CONTEXT: @{.workflow/{test_session_id}/.process/test-context-package.toon}

**MANDATORY FIRST STEP**: Read and analyze test-context-package.toon to understand:
- Test coverage gaps from test_coverage.missing_tests[]
- Implementation context from source_context.implementation_summaries[]
- Existing test patterns from test_framework.conventions
- Changed files requiring tests from source_context.implementation_summaries[].changed_files

**ANALYSIS REQUIREMENTS**:

1. **Implementation Understanding**
   - Load all implementation summaries from source session
   - Understand implemented features, APIs, and business logic
   - Extract key functions, classes, and modules
   - Identify integration points and dependencies

2. **Existing Test Pattern Analysis**
   - Study existing test files for patterns and conventions
   - Identify test structure (describe/it, test suites, fixtures)
   - Analyze assertion patterns and mocking strategies
   - Extract test setup/teardown patterns

3. **Coverage Gap Assessment**
   - For each file in missing_tests[], analyze:
     - File purpose and functionality
     - Public APIs requiring test coverage
     - Critical paths and edge cases
     - Integration points requiring tests
   - Prioritize tests: high (core logic), medium (utilities), low (helpers)

4. **Test Requirements Specification**
   - For each missing test file, specify:
     - **Test scope**: What needs to be tested
     - **Test scenarios**: Happy path, error cases, edge cases, integration
     - **Test data**: Required fixtures, mocks, test data
     - **Dependencies**: External services, databases, APIs to mock
     - **Coverage targets**: Functions/methods requiring tests

5. **Test Generation Strategy**
   - Determine test generation approach for each file
   - Identify reusable test patterns from existing tests
   - Plan test data and fixture requirements
   - Define mocking strategy for dependencies
   - Specify expected test file structure

EXPECTED OUTPUT - Write to gemini-test-analysis.md:

# Test Generation Analysis

## 1. Implementation Context Summary
- **Source Session**: {source_session_id}
- **Implemented Features**: {feature_summary}
- **Changed Files**: {list_of_implementation_files}
- **Tech Stack**: {technologies_used}

## 2. Test Coverage Assessment
- **Existing Tests**: {count} files
- **Missing Tests**: {count} files
- **Coverage Percentage**: {percentage}%
- **Priority Breakdown**:
  - High Priority: {count} files (core business logic)
  - Medium Priority: {count} files (utilities, helpers)
  - Low Priority: {count} files (configuration, constants)

## 3. Existing Test Pattern Analysis
- **Test Framework**: {framework_name_and_version}
- **File Naming Convention**: {pattern}
- **Test Structure**: {describe_it_or_other}
- **Assertion Style**: {expect_assert_should}
- **Mocking Strategy**: {mocking_framework_and_patterns}
- **Setup/Teardown**: {beforeEach_afterEach_patterns}
- **Test Data**: {fixtures_factories_builders}

## 4. Test Requirements by File

### File: {implementation_file_path}
**Test File**: {suggested_test_file_path}
**Priority**: {high|medium|low}

#### Scope
- {description_of_what_needs_testing}

#### Test Scenarios
1. **Happy Path Tests**
   - {scenario_1}
   - {scenario_2}

2. **Error Handling Tests**
   - {error_scenario_1}
   - {error_scenario_2}

3. **Edge Case Tests**
   - {edge_case_1}
   - {edge_case_2}

4. **Integration Tests** (if applicable)
   - {integration_scenario_1}
   - {integration_scenario_2}

#### Test Data & Fixtures
- {required_test_data}
- {required_mocks}
- {required_fixtures}

#### Dependencies to Mock
- {external_service_1}
- {external_service_2}

#### Coverage Targets
- Function: {function_name} - {test_requirements}
- Function: {function_name} - {test_requirements}

---
[Repeat for each missing test file]
---

## 5. Test Generation Strategy

### Overall Approach
- {strategy_description}

### Test Generation Order
1. {file_1} - {rationale}
2. {file_2} - {rationale}
3. {file_3} - {rationale}

### Reusable Patterns
- {pattern_1_from_existing_tests}
- {pattern_2_from_existing_tests}

### Test Data Strategy
- {approach_to_test_data_and_fixtures}

### Mocking Strategy
- {approach_to_mocking_dependencies}

### Quality Criteria
- Code coverage target: {percentage}%
- Test scenarios per function: {count}
- Integration test coverage: {approach}

## 6. Implementation Targets

**Purpose**: Identify new test files to create

**Format**: New test files only (no existing files to modify)

**Test Files to Create**:
1. **Target**: `tests/auth/TokenValidator.test.ts`
   - **Type**: Create new test file
   - **Purpose**: Test TokenValidator class
   - **Scenarios**: 15 test cases covering validation logic, error handling, edge cases
   - **Dependencies**: Mock JWT library, test fixtures for tokens

2. **Target**: `tests/middleware/errorHandler.test.ts`
   - **Type**: Create new test file
   - **Purpose**: Test error handling middleware
   - **Scenarios**: 8 test cases for different error types and response formats
   - **Dependencies**: Mock Express req/res/next, error fixtures

[List all test files to create]

## 7. Success Metrics
- **Test Coverage Goal**: {target_percentage}%
- **Test Quality**: All scenarios covered (happy, error, edge, integration)
- **Convention Compliance**: Follow existing test patterns
- **Maintainability**: Clear test descriptions, reusable fixtures

RULES:
- Focus on TEST REQUIREMENTS and GENERATION STRATEGY, NOT code generation
- Study existing test patterns thoroughly for consistency
- Prioritize critical business logic tests
- Specify clear test scenarios and coverage targets
- Identify all dependencies requiring mocks
- **MUST write output to .workflow/{test_session_id}/.process/gemini-test-analysis.md**
- Do NOT generate actual test code or implementation
- Output ONLY test analysis and generation strategy
" --approval-mode yolo
```

**Output Location**: `.workflow/{test_session_id}/.process/gemini-test-analysis.md`

### Phase 3: Results Synthesis

1. **Output Validation**
   - Verify `gemini-test-analysis.md` exists and is complete
   - Validate all required sections present
   - Check test requirements are actionable

2. **Quality Assessment**
   - Test scenarios cover happy path, errors, edge cases
   - Dependencies and mocks clearly identified
   - Test generation strategy is practical
   - Coverage targets are reasonable

### Phase 4: TEST_ANALYSIS_RESULTS.md Generation

Synthesize Gemini analysis into standardized format:

```markdown
# Test Generation Analysis Results

## Executive Summary
- **Test Session**: {test_session_id}
- **Source Session**: {source_session_id}
- **Analysis Timestamp**: {timestamp}
- **Coverage Gap**: {missing_test_count} files require tests
- **Test Framework**: {framework}
- **Overall Strategy**: {high_level_approach}

---

## 1. Coverage Assessment

### Current Coverage
- **Existing Tests**: {count} files
- **Implementation Files**: {count} files
- **Coverage Percentage**: {percentage}%

### Missing Tests (Priority Order)
1. **High Priority** ({count} files)
   - {file_1} - {reason}
   - {file_2} - {reason}

2. **Medium Priority** ({count} files)
   - {file_1} - {reason}

3. **Low Priority** ({count} files)
   - {file_1} - {reason}

---

## 2. Test Framework & Conventions

### Framework Configuration
- **Framework**: {framework_name}
- **Version**: {version}
- **Test Pattern**: {file_pattern}
- **Test Directory**: {directory_structure}

### Conventions
- **File Naming**: {convention}
- **Test Structure**: {describe_it_blocks}
- **Assertions**: {assertion_library}
- **Mocking**: {mocking_framework}
- **Setup/Teardown**: {beforeEach_afterEach}

### Example Pattern (from existing tests)
```
{example_test_structure_from_analysis}
```

---

## 3. Test Requirements by File

[For each missing test, include:]

### Test File: {test_file_path}
**Implementation**: {implementation_file}
**Priority**: {high|medium|low}
**Estimated Test Count**: {count}

#### Test Scenarios
1. **Happy Path**: {scenarios}
2. **Error Handling**: {scenarios}
3. **Edge Cases**: {scenarios}
4. **Integration**: {scenarios}

#### Dependencies & Mocks
- {dependency_1_to_mock}
- {dependency_2_to_mock}

#### Test Data Requirements
- {fixture_1}
- {fixture_2}

---

## 4. Test Generation Strategy

### Generation Approach
{overall_strategy_description}

### Generation Order
1. {test_file_1} - {rationale}
2. {test_file_2} - {rationale}
3. {test_file_3} - {rationale}

### Reusable Components
- **Test Fixtures**: {common_fixtures}
- **Mock Patterns**: {common_mocks}
- **Helper Functions**: {test_helpers}

### Quality Targets
- **Coverage Goal**: {percentage}%
- **Scenarios per Function**: {min_count}
- **Integration Coverage**: {approach}

---

## 5. Implementation Targets

**Purpose**: New test files to create (code-developer will generate these)

**Test Files to Create**:

1. **Target**: `tests/auth/TokenValidator.test.ts`
   - **Implementation Source**: `src/auth/TokenValidator.ts`
   - **Test Scenarios**: 15 (validation, error handling, edge cases)
   - **Dependencies**: Mock JWT library, token fixtures
   - **Priority**: High

2. **Target**: `tests/middleware/errorHandler.test.ts`
   - **Implementation Source**: `src/middleware/errorHandler.ts`
   - **Test Scenarios**: 8 (error types, response formats)
   - **Dependencies**: Mock Express, error fixtures
   - **Priority**: High

[List all test files with full specifications]

---

## 6. Success Criteria

### Coverage Metrics
- Achieve {target_percentage}% code coverage
- All public APIs have tests
- Critical paths fully covered

### Quality Standards
- All test scenarios covered (happy, error, edge, integration)
- Follow existing test conventions
- Clear test descriptions and assertions
- Maintainable test structure

### Validation Approach
- Run full test suite after generation
- Verify coverage with coverage tool
- Manual review of test quality
- Integration test validation

---

## 7. Reference Information

### Source Context
- **Implementation Summaries**: {paths}
- **Existing Tests**: {example_tests}
- **Documentation**: {relevant_docs}

### Analysis Tools
- **Gemini Analysis**: gemini-test-analysis.md
- **Coverage Tools**: {coverage_tool_if_detected}
```

**Output Location**: `.workflow/{test_session_id}/.process/TEST_ANALYSIS_RESULTS.md`

## Error Handling

### Validation Errors
| Error | Cause | Resolution |
|-------|-------|------------|
| Missing context package | test-context-gather not run | Run test-context-gather first |
| No coverage gaps | All files have tests | Skip test generation, proceed to test execution |
| No test framework detected | Missing test dependencies | Request user to configure test framework |
| Invalid source session | Source session incomplete | Complete implementation first |

### Gemini Execution Errors
| Error | Cause | Recovery |
|-------|-------|----------|
| Timeout | Large project analysis | Reduce scope, analyze by module |
| Output incomplete | Token limit exceeded | Retry with focused analysis |
| No output file | Write permission error | Check directory permissions |

### Fallback Strategy
- If Gemini fails, generate basic TEST_ANALYSIS_RESULTS.md from context package
- Use coverage gaps and framework info to create minimal requirements
- Provide guidance for manual test planning

## Performance Optimization

- **Focused Analysis**: Only analyze files with missing tests
- **Pattern Reuse**: Study existing tests for quick pattern extraction
- **Parallel Operations**: Load implementation summaries in parallel
- **Timeout Management**: 20-minute limit for Gemini analysis

## Integration

### Called By
- `/workflow:test-gen` (Phase 4: Analysis)

### Requires
- `/workflow:tools:test-context-gather` output (test-context-package.toon)

### Followed By
- `/workflow:tools:test-task-generate` - Generates test task TOON with code-developer invocation

## Success Criteria

- ✅ Valid TEST_ANALYSIS_RESULTS.md generated
- ✅ All missing tests documented with requirements
- ✅ Test scenarios cover happy path, errors, edge cases
- ✅ Dependencies and mocks identified
- ✅ Test generation strategy is actionable
- ✅ Execution time < 20 minutes
- ✅ Output follows existing test conventions

