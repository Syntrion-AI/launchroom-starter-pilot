#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_SURFACES = ['desktop','telegram','slack','email','discord','teams_matrix_signal_whatsapp','webhooks_api']
REQUIRED_FIELDS = ['role','manager','best_for','real_options','official_sources','gates','verification']
REQUIRED_MANAGERS = ['hermes_desktop','hermes_gateway_telegram','hermes_gateway_slack','hermes_gateway_email','hermes_gateway_discord','hermes_gateway_platform_adapter','hermes_webhook_or_api_server']
REQUIRED_SOURCES = [
    'https://hermes-agent.nousresearch.com/docs/user-guide/messaging/',
    'https://hermes-agent.nousresearch.com/docs/reference/cli-commands',
    'https://hermes-agent.nousresearch.com/docs/user-guide/features/webhooks',
    'https://core.telegram.org/bots/api',
    'https://api.slack.com/apis/connections/socket',
    'https://api.slack.com/reference/manifests',
    'https://discord.com/developers/docs/intro',
]

def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'messaging.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-communication-channel-map-v0_6':
        print('FAIL: unexpected messaging recipe_id')
        return 1
    contract_path = ROOT / recipe.get('stage_5_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 5 contract missing')
        return 1
    contract_text = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_5_COMMUNICATION_SURFACES_AND_CHANNEL_MANAGERS_v0_1',
        'communication-channel-map.yaml',
        'communication-user-guide.md',
        'Communication Surfaces & Channel Managers',
        'safe secret-entry path',
        'gateway_setup: false',
        'pairing_approved: false',
        'home_channel_set: false',
        'gateway_autostart_installed: false',
        'test_message_sent: false',
    ]:
        if marker not in contract_text:
            print('FAIL: Stage 5 contract marker missing: ' + marker)
            return 1
    for surface in REQUIRED_SURFACES:
        if surface not in recipe.get('required_surfaces', []):
            print('FAIL: messaging recipe missing surface: ' + surface)
            return 1
        if surface not in contract_text:
            print('FAIL: Stage 5 contract missing surface: ' + surface)
            return 1
    for field in REQUIRED_FIELDS:
        if field not in recipe.get('required_fields_per_surface', []):
            print('FAIL: messaging recipe missing required field: ' + field)
            return 1
    for manager in REQUIRED_MANAGERS:
        if manager not in recipe.get('channel_managers', []):
            print('FAIL: messaging recipe missing manager: ' + manager)
            return 1
        if manager not in contract_text:
            print('FAIL: Stage 5 contract missing manager: ' + manager)
            return 1
    for source in REQUIRED_SOURCES:
        if source not in recipe.get('official_sources', []):
            print('FAIL: messaging recipe missing source: ' + source)
            return 1
        if source not in contract_text:
            print('FAIL: Stage 5 contract missing source: ' + source)
            return 1
    forbidden = recipe.get('forbidden_without_gate', [])
    for item in ['ask token in chat','print token','store token in repo or reports','run gateway setup','approve pairing','set home channel','install gateway autostart','send test message','mutate n8n/cloud/runtime/provider surfaces']:
        if item not in forbidden:
            print('FAIL: messaging forbidden_without_gate missing: ' + item)
            return 1
    print('validate_messaging_contract: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
