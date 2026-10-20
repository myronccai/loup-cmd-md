# Tasks: md

- [x] 1. Copy the shared Windows code into `source/win/` (f601bf9)
  - _Requirements: 1.3, 3.2_
- [x] 2. Parse md's command line (no switches, `/?`, `--`, `--version`)
  - _Requirements: 3.1, 3.2, 3.3_
- [x] 3. Resolve operands: separators, `.` and `..`, invalid characters
  - _Requirements: 1.3, 2.3_
- [x] 4. Check before creating: existing entries (also dangling links), blocked paths
  - _Requirements: 2.1, 2.2_
- [x] 5. Create with parents and verify; `Access is denied.`
  - _Requirements: 1.1, 1.4, 2.4_
- [x] 6. Several operands, `Error occurred while processing`, exit statuses
  - _Requirements: 1.2, 2.5, 2.6, 2.7_
- [x] 7. The `mkdir` link
  - _Requirements: 3.4_
- [x] 8. Unit tests and end-to-end tests of the native binary
  - _Requirements: all_
