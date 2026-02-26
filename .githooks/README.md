# Git Hooks for HIVMeet

This directory contains custom Git hooks to enforce code quality and security standards.

## Available Hooks

### pre-commit-pii-check

**Purpose:** Prevents committing code that logs Personally Identifiable Information (PII).

**What it detects:**
- `print()` statements logging user IDs (user_id, userId, profile.id)
- `print()` statements logging names (profile.name, displayName)
- `print()` statements logging email addresses
- `print()` statements logging authentication tokens
- `print()` statements logging API response data (potential PII)

**How to install:**

#### Option 1: Configure Git to use this hooks directory (Recommended)
```bash
git config core.hooksPath .githooks
```

This will make Git use all hooks in the `.githooks` directory.

#### Option 2: Copy individual hooks to .git/hooks
```bash
cp .githooks/pre-commit-pii-check .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**How to use:**

Once installed, the hook runs automatically before each commit. If PII logging is detected, the commit will be blocked with an error message showing the violations.

**How to fix violations:**

1. **Remove the print() statement** (recommended for production code)
   ```dart
   // ❌ Bad - Logs PII
   print('User ID: $userId');

   // ✅ Good - No logging
   // Removed debug statement
   ```

2. **Sanitize the output** to remove PII
   ```dart
   // ❌ Bad - Logs user name
   print('Profile liked: ${profile.name}');

   // ✅ Good - Sanitized
   print('Profile like action completed'); // No PII
   ```

3. **Mark as safe** if you verified it doesn't contain PII
   ```dart
   // ✅ Safe - Only counts, no user data
   print('Total profiles: $count'); // SAFE: No PII logged
   ```

**Bypassing the hook (NOT RECOMMENDED):**

If you absolutely must bypass the check:
```bash
git commit --no-verify
```

⚠️ **WARNING:** Only bypass if you're certain your code doesn't log PII. Logging PII violates GDPR and privacy regulations.

## Why This Matters

HIVMeet serves people living with HIV/AIDS. Privacy and data protection are **critical**:

- **GDPR Compliance:** Logging PII can violate data protection regulations
- **User Trust:** Users expect their sensitive information to be protected
- **Security:** Logs can be accessed by unauthorized parties
- **Compliance:** CLAUDE.md Rule #5 explicitly prohibits PII logging

## Maintenance

To update the hooks:
1. Edit the hook file in `.githooks/`
2. Test the hook with sample violations
3. Commit the changes
4. Team members will get the updated hook on next pull

## Testing the Hook

Test that the hook works:

```bash
# Create a test file with PII logging
echo 'print("User ID: \$userId");' > test_pii.dart
git add test_pii.dart
git commit -m "Test PII detection"
# Should block the commit

# Clean up
git reset HEAD test_pii.dart
rm test_pii.dart
```

## Support

If you have questions or need help with the hooks, contact the development team or refer to `CLAUDE.md`.
