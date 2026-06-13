#!/usr/bin/env bash
#
# foundry-agent-region-check.sh
#
# Determines which Azure regions can host Microsoft Foundry (the AIServices
# account) AND the Foundry Agent Service, for the CURRENT subscription.
#
# Why this is a hybrid check:
#   There is no `az` command that returns "Agent Service regions" directly.
#   Per Microsoft docs, Agent Service is only available in regions that
#   support the Azure OpenAI Responses API. That list is documentation-
#   maintained, so it is encoded below (RESPONSES_API_REGIONS) and must be
#   refreshed when the docs change:
#   https://learn.microsoft.com/azure/foundry/openai/how-to/responses#supported-regions
#   https://learn.microsoft.com/azure/foundry/agents/concepts/limits-quotas-regions#supported-regions
#
# What the script verifies live, per region, against your subscription:
#   1. AIServices account kind is creatable (Foundry resource)  -> via SKU list
#
# Requires: az CLI (logged in)
# Usage:    ./foundry-agent-region-check.sh [GLOB]
#           SUBSCRIPTION="<sub-id>" ./foundry-agent-region-check.sh [GLOB]
#
#   GLOB  Optional shell glob to filter regions (case-insensitive). Examples:
#           'eastus*'   -> eastus, eastus2
#           '*europe*'  -> (none in list; matches by substring)
#           'us*|*us'   -> not supported; pass a single glob, run again for more
#         When omitted, all Responses-API regions are checked.

set -euo pipefail

REGION_GLOB="${1:-*}"

# --- Canonical Responses API region list (doc snapshot, June 2026) -----------
# Source: Azure OpenAI Responses API "Supported regions". UPDATE WHEN DOCS CHANGE.
RESPONSES_API_REGIONS=(
  australiaeast brazilsouth canadacentral canadaeast eastus eastus2
  francecentral germanywestcentral italynorth japaneast koreacentral
  northcentralus norwayeast polandcentral southafricanorth southcentralus
  southeastasia southindia spaincentral swedencentral switzerlandnorth
  uaenorth uksouth westus westus3
)

# --- Setup -------------------------------------------------------------------
command -v az >/dev/null || { echo "az CLI not found" >&2; exit 1; }

# Filter the canonical list by the glob (case-insensitive).
shopt -s nocasematch
REGIONS=()
for region in "${RESPONSES_API_REGIONS[@]}"; do
  # shellcheck disable=SC2053
  [[ "$region" == $REGION_GLOB ]] && REGIONS+=("$region")
done
shopt -u nocasematch

if [[ ${#REGIONS[@]} -eq 0 ]]; then
  echo "No Responses-API regions match glob: $REGION_GLOB" >&2
  exit 1
fi

SUB="${SUBSCRIPTION:-$(az account show --query id -o tsv)}"
echo "Subscription: $SUB" >&2
echo "Checking ${#REGIONS[@]} of ${#RESPONSES_API_REGIONS[@]} Responses-API regions (glob: $REGION_GLOB)..." >&2
echo >&2

# Where can the AIServices (Foundry) account kind be created in this sub?
# Returns a newline-separated list of locations supporting kind=AIServices.
# Note: read into an array via a loop (not `mapfile`) for Bash 3.2 (macOS) support.
AISERVICES_LOCATIONS=()
while IFS= read -r _loc; do
  [[ -n "$_loc" ]] && AISERVICES_LOCATIONS+=("$_loc")
done < <(
  az cognitiveservices account list-skus \
    --kind AIServices \
    --subscription "$SUB" \
    --query "[].locations[]" -o tsv 2>/dev/null \
  | tr '[:upper:] ' '[:lower:]' | tr -d ' ' | sort -u
)

is_in_array() { local n="$1"; shift; for x in "$@"; do [[ "$x" == "$n" ]] && return 0; done; return 1; }

# --- Probe each region -------------------------------------------------------
printf "%-20s %-14s\n" "REGION" "FOUNDRY_ACCT"
printf "%-20s %-14s\n" "------" "------------"

for region in "${REGIONS[@]}"; do
  # Foundry account creatable here?
  if is_in_array "$region" "${AISERVICES_LOCATIONS[@]:-}"; then
    foundry="yes"
  else
    foundry="NO"
  fi

  printf "%-20s %-14s\n" "$region" "$foundry"
done

echo >&2
echo "Notes:" >&2
echo " - FOUNDRY_ACCT=yes means: the AIServices (Foundry) account kind is" >&2
echo "   creatable in this region for your subscription." >&2
echo " - Regions listed are those on the Azure OpenAI Responses-API list, which" >&2
echo "   Agent Service requires. Confirm a compatible model is deployable there." >&2
echo " - Quota is separate. A 'yes' here does not guarantee capacity." >&2