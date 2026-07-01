# Publication Gate

This local rebuild does not authorize public publication.

Before push, tag, release, or public raw-link claims:

1. Run all validators.
2. Check git diff and file list.
3. Confirm no secrets or private AIRMIDA paths are introduced into public docs.
4. Obtain an explicit owner publication gate.
5. After push, verify remote SHA, raw URLs, and GitHub Actions success.
