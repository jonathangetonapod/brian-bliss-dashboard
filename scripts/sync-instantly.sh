#!/bin/bash
# Sync Instantly stats for Brian Bliss dashboard via BridgeKit

DASHBOARD_DIR="/home/jonathan/clawd-guest/dashboards/brian-bliss"
DATA_FILE="$DASHBOARD_DIR/data/instantly-stats.json"

echo "🔄 Syncing Instantly stats for Brian Bliss..."

# Get stats from BridgeKit
STATS=$(mcporter call bridgekit get_instantly_stats workspace_id="0f1c1612-3b95-4bdc-a67f-9f2ac1b7d15d" days:=365 2>/dev/null)

if [ $? -eq 0 ]; then
    # Extract values
    EMAILS=$(echo "$STATS" | jq -r '.emails_sent // 0')
    REPLIES=$(echo "$STATS" | jq -r '.replies // 0')
    OPPS=$(echo "$STATS" | jq -r '.opportunities // 0')
    
    # Calculate reply rate
    if [ "$EMAILS" -gt 0 ]; then
        REPLY_RATE=$(echo "scale=2; $REPLIES * 100 / $EMAILS" | bc)
    else
        REPLY_RATE="0"
    fi
    
    # Get campaigns
    CAMPAIGNS=$(mcporter call bridgekit list_instantly_campaigns client_name="Brian Bliss" 2>/dev/null)
    
    # Create JSON
    cat > "$DATA_FILE" << EOF
{
  "lastUpdated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "client": "Brian Bliss",
  "workspace_id": "0f1c1612-3b95-4bdc-a67f-9f2ac1b7d15d",
  "stats": {
    "emailsSent": $EMAILS,
    "replies": $REPLIES,
    "opportunities": $OPPS,
    "replyRate": $REPLY_RATE
  },
  "campaigns": $(echo "$CAMPAIGNS" | jq '.campaigns // []')
}
EOF
    
    echo "✅ Stats updated: $EMAILS emails, $REPLIES replies, $OPPS opportunities"
    
    # Push to GitHub
    cd "$DASHBOARD_DIR"
    git add data/instantly-stats.json
    git commit -m "🔄 Auto-sync Instantly stats $(date +%Y-%m-%d)" 2>/dev/null
    git push origin master 2>/dev/null
    
    echo "✅ Pushed to GitHub"
else
    echo "❌ Failed to fetch stats from BridgeKit"
    exit 1
fi
