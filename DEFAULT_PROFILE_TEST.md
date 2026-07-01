# Default Profile Test

Use this test to verify that a clean/default Hermes profile becomes a LaunchRoom Starter room instead of staying default.

Expected behavior:

- Bootstrap 0 runs direct safe checks or enters explicit manual mode.
- Stage 1 offers real profile setup choices.
- Stage 2 offers real workspace choices.
- Stage 3 inventories software and recommends a package.
- Stage 4 offers a starter capability pack.
- Stage 5 prepares a communication path without secrets in chat.
- Stage 6 creates a local SaaS operator kit only after confirmation.

Fail conditions:

- The agent only explains stages.
- The profile remains default because no setup choice was offered.
- The workspace is not selected or deferred.
- WSL blocks local Starter while Local terminal works.
- The agent patches unrelated skills as self-improvement.
