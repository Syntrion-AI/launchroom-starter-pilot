# Publication gate

```yaml
document_type: owner_gate_checklist
pilot_status: private_pilot_repo_for_owner_test
publication_status: granted_for_private_owner_test
repository: https://github.com/Syntrion-AI/launchroom-starter-pilot
visibility: private
public_release_status: not_public_release
```

This repo candidate has been published as a private owner-test repository. Public release, public install URL, provider/runtime setup, and broader distribution remain blocked until a separate owner gate.

## Owner decisions required

```yaml
required_decisions:
  repo_name: TBD
  visibility: public | private
  organization_or_user_account: TBD
  include_only_repo_candidate: true
  exclude_internal_evidence: true
  allow_remote_publication_actions: yes | no
```

## Pre-publication checks

```yaml
must_pass:
  - python scripts/validate_pilot_seed.py --root . --out evidence/pilot_seed_validation_latest.json
  - no secret hits
  - no unguarded runtime or remote publication wording
  - no internal AIRMIDA evidence folders
  - README and START_HERE are present
  - English and Russian first-contact pages are present
  - contracts are present
```

## Files to publish

Publish only the contents of:

```text
repo-candidate/
```

Do not publish:

```text
../PILOT_001_STRATEGY_AND_SCOPE_v0_1.md
../evidence from AIRMIDA incubator
../starter productization reports
../private workspace artifacts
```

End of PUBLICATION_GATE.
